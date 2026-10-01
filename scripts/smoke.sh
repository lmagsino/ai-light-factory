#!/usr/bin/env bash
# Smoke test for alf's scripts: readiness gate, seats, dispatch (with a fake
# claude), wait, board, ledger, stats, limits, and the guard hook. No network, no gh.
# shellcheck disable=SC2015  # ok() always succeeds, so `A && ok || fail` is safe here
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$HERE/bin"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
pass=0
ok()   { printf '  ok  %s\n' "$1"; pass=$((pass + 1)); }
# portable timeout (macOS has no GNU timeout)
with_timeout() { local s="$1"; shift; "$@" & local p=$!; ( sleep "$s"; kill "$p" 2>/dev/null ) & local w=$!; wait "$p"; local r=$?; kill "$w" 2>/dev/null; return $r; }
fail() { printf 'FAIL  %s\n' "$1" >&2; exit 1; }

echo "== repo fixture"
git init -q --bare "$T/origin.git"
git clone -q "$T/origin.git" "$T/app" 2>/dev/null
cd "$T/app"
git config user.email smoke@example.com && git config user.name smoke
echo "hello" > README.md && git add . && git commit -qm init && git branch -M main && git push -q -u origin main 2>/dev/null
mkdir -p .factory
jq '.repo.integration_branch="main" | .commands.test="true" | .seats.reviewer.vendor="claude"' \
  "$HERE/templates/config.json" > .factory/config.json

echo "== readiness gate (to-tickets issue format)"
cat > "$T/good.md" <<'MD'
## Parent

#40

## What to build

A user can export an invoice as CSV.

## Acceptance criteria

- [ ] Export downloads one row per line item
- [ ] Amounts are in cents

## Blocked by

- None (can start immediately)
MD
"$BIN/alf-ready" --file "$T/good.md" >/dev/null && ok "a to-tickets issue is READY" || fail "complete ticket rejected"
sed -e 's/Amounts are in cents/Amounts TBD/' -e '/## Blocked by/,$d' "$T/good.md" > "$T/bad.md"
printf '## Size\n\nM\n' >> "$T/bad.md"
out="$("$BIN/alf-ready" --file "$T/bad.md" || true)"
grep -q "NOT READY" <<<"$out" && grep -q "Size is M" <<<"$out" && grep -q "TBD" <<<"$out" && grep -q "Blocked by is missing" <<<"$out" \
  && ok "an incomplete ticket is NOT READY with three reasons" || fail "bad ticket: $out"

echo "== seats"
read -r seat path < <("$BIN/alf-seat" acquire developer --ticket 1)
[[ "$seat" == Developer && -d "$path" ]] && ok "acquire gives Developer" || fail "acquire: $seat $path"
read -r seat2 _ < <("$BIN/alf-seat" acquire developer --ticket 2)
[[ "$seat2" == Developer-2 ]] && ok "second acquire gives Developer-2" || fail "second acquire: $seat2"
if "$BIN/alf-seat" acquire developer --ticket 3 >/dev/null; then fail "third developer seat was granted"; else ok "no Developer-3: two is the ceiling"; fi
"$BIN/alf-seat" release Developer-2 >/dev/null
echo "wip" > "$path/wip.txt"
"$BIN/alf-seat" release Developer >/dev/null
sweep="$("$BIN/alf-seat" sweep)"
grep -q "KEEP    Developer " <<<"$sweep" && [[ -f "$path/wip.txt" ]] && ok "sweep keeps a seat with uncommitted work" || fail "sweep: $sweep"
grep -q "REMOVE  Developer-2" <<<"$sweep" && ok "sweep removes a clean overflow seat" || fail "sweep: $sweep"
rm "$path/wip.txt"

echo "== dispatch / wait with a fake claude"
mkdir -p "$T/fakebin"
cat > "$T/fakebin/claude" <<'SH'
#!/usr/bin/env bash
cat >/dev/null
echo '{"type":"system","subtype":"init"}'
sleep 1
echo '{"type":"result","result":"built it\nALF developer DONE branch=factory/1-x sha=abc1234 tests=green","total_cost_usd":0.42,"num_turns":7}'
SH
chmod +x "$T/fakebin/claude"
export PATH="$T/fakebin:$PATH"
RUN="$T/app/.factory/runs/smoke"
mkdir -p "$RUN"
read -r seat _ < <("$BIN/alf-seat" acquire developer --ticket 1 --run "$RUN")
echo "Seat contract: $HERE/skills/dev-loop/seats/developer.md. mode: build. Write findings to $RUN/1/not-yet-written.md" > "$RUN/p.md"
"$BIN/alf-dispatch" developer "$seat" "$RUN" "$RUN/p.md" --ticket 1 >/dev/null && ok "dispatch starts"
line="$(with_timeout 30 "$BIN/alf-wait" "$RUN" --interval-sec 1)"
grep -q "ALF developer DONE" <<<"$line" && ok "wait returns the status line" || fail "wait: $line"
[[ "$(jq -r .cost_usd "$RUN/seats/$seat.1.json")" == 0.42 ]] && ok "cost recorded" || fail "cost not recorded"
grep -q "same_vendor=false" <<<"$line" && ok "status line carries vendor provenance" || fail "no provenance: $line"

echo "Seat contract: $HERE/skills/dev-loop/seats/developer.md. How to build: /nope/SKILL.md" > "$RUN/bad.md"
read -r seat _ < <("$BIN/alf-seat" acquire developer --ticket 2 --run "$RUN")
if "$BIN/alf-dispatch" developer "$seat" "$RUN" "$RUN/bad.md" 2>/dev/null; then fail "dispatched with a missing skill"; else ok "refuses a companion SKILL.md path that does not resolve"; fi
echo "Seat contract: $HERE/skills/dev-loop/seats/developer.md. How to build: skills/x/SKILL.md" > "$RUN/rel.md"
if "$BIN/alf-dispatch" developer "$seat" "$RUN" "$RUN/rel.md" 2>/dev/null; then fail "dispatched with a relative skill path"; else ok "refuses a relative SKILL.md path"; fi
echo "Just do the ticket." > "$RUN/none.md"
if "$BIN/alf-dispatch" developer "$seat" "$RUN" "$RUN/none.md" 2>/dev/null; then fail "dispatched with no seat contract"; else ok "refuses a prompt that names no seat contract"; fi
"$BIN/alf-seat" release "$seat" >/dev/null

cat > "$T/fakebin/claude" <<'SH'
#!/usr/bin/env bash
cat >/dev/null
echo '{"type":"result","result":"I did some things","total_cost_usd":0.1,"num_turns":2}'
SH
read -r seat _ < <("$BIN/alf-seat" acquire developer --ticket 3 --run "$RUN")
"$BIN/alf-dispatch" developer "$seat" "$RUN" "$RUN/p.md" --ticket 3 >/dev/null
line="$(with_timeout 30 "$BIN/alf-wait" "$RUN" --interval-sec 1)"
grep -q "NOT_RUN" <<<"$line" && ok "no status line is recorded as NOT_RUN" || fail "missing status line: $line"

echo "== any agent CLI in a seat, with git and gh routed through the shims"
cat > "$T/fakebin/other-agent" <<'SH'
#!/usr/bin/env bash
cat >/dev/null
# a non-Claude agent trying the forbidden things, then reporting
git push origin main >/dev/null 2>&1 && echo "PUSHED-MAIN"
gh pr merge 12 >/dev/null 2>&1 && echo "MERGED"
gh pr create --base main --title x --body y >/dev/null 2>&1 && echo "NON-DRAFT"
echo "ALF developer DONE branch=factory/9-x sha=abc1234 tests=green"
SH
cat > "$T/fakebin/gh" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$T/fakebin/other-agent" "$T/fakebin/gh"
jq '.seats.developer.vendor="other" | .seats.developer.command="other-agent"' .factory/config.json > c.tmp && mv c.tmp .factory/config.json
read -r seat _ < <("$BIN/alf-seat" acquire developer --ticket 9 --run "$RUN")
"$BIN/alf-dispatch" developer "$seat" "$RUN" "$RUN/p.md" --ticket 9 >/dev/null
line="$(with_timeout 30 "$BIN/alf-wait" "$RUN" --interval-sec 1)"
log="$(jq -r .log "$(grep -l "\"ticket\": \"9\"" "$RUN"/seats/*.json | head -1)")"
grep -q "ALF developer DONE" <<<"$line" && ok "a custom agent command runs in a seat" || fail "custom agent: $line"
grep -q "vendor=other" <<<"$line" && ok "its vendor is recorded" || fail "vendor: $line"
! grep -qE "PUSHED-MAIN|MERGED|NON-DRAFT" "$log" && ok "the shims block push-to-main, merge and non-draft PRs for a non-Claude agent" || fail "shims let it through: $(cat "$log")"
jq '.seats.developer.vendor="claude" | .seats.developer.command=""' .factory/config.json > c.tmp && mv c.tmp .factory/config.json

echo "== board"
cat > "$RUN/state.json" <<'JSON'
{"run":"smoke","lanes":2,"budget":4,"tip":"#66","tickets":[
 {"id":63,"key":"T1.6","title":"Column registry","flag":"LANE","seat":"Developer-2","state":"building","next":"review"},
 {"id":65,"key":"T1.7","title":"Retry policy","flag":"WAIT","state":"blocked by #63"},
 {"id":61,"key":"T1.4","title":"Currency rounding","flag":"PARK","pr":64,"sha":"a19f003aaaa","state":"round 2: High survives","next":"needs you"}
]}
JSON
board="$("$BIN/alf-board" "$RUN")"
first_row="$(sed -n '5p' <<<"$board")"
[[ "$first_row" == PARK* ]] && ok "board puts PARK first" || fail "board order: $board"
grep -q "^CHECK .*no live agent" <<<"$board" && ok "board flags a LANE with no live agent as CHECK" || fail "board check: $board"
widths="$(sed -n '4,7p' <<<"$board" | awk '{ print index($0, "SEAT") + 0 }' | head -1)"
[[ -n "$widths" ]] && ok "board renders"

echo "== ledger and stats"
"$BIN/alf-ledger" ticket "$RUN" 1 drafted pr=10 rounds=1 fixed=2 not_addressed=0 dropped=1 >/dev/null
"$BIN/alf-ledger" ticket "$RUN" 3 parked reason="no status line" >/dev/null
stats="$("$BIN/alf-stats" --no-gh)"
grep -q "Reached a draft PR | 1 (50%)" <<<"$stats" && grep -q "no status line x1" <<<"$stats" \
  && ok "stats count drafted and parked with reasons" || fail "stats: $stats"

echo "== guard hook"
G="$HERE/hooks/guard.py"
j() { jq -nc --arg c "$1" --arg cwd "$T/app" '{session_id:"s1", cwd:$cwd, tool_name:"Bash", tool_input:{command:$c}}'; }
code() { set +e; ALF_SEAT="${SEATENV-Developer}" python3 "$G" <<<"$(j "$1")" 2>/dev/null; local r=$?; set -e; echo $r; }
while IFS= read -r c; do
  [[ "$(code "$c")" == 2 ]] && ok "blocks: $c" || fail "did not block: $c"
done <<'CMDS'
gh pr merge 12 --squash
gh -R o/r pr merge 12
gh pr ready 12
gh pr review 12 --approve
gh pr create --base main --title x --body y
git push origin main
git -C /tmp/x push origin main
git push -u origin HEAD:main
git push --force origin factory/1-x
git push -f origin factory/1-x
git push -fu origin factory/1-x
git push origin +factory/1-x
gh api repos/o/r/pulls/12/merge -X PUT
gh api -X PUT repos/o/r/pulls/$N/merge
gh api repos/o/r/pulls/12/reviews --input body.json
gh api graphql -F query=@m.graphql
bash -c "gh pr merge 12"
npm test && gh pr merge 12
CMDS
while IFS= read -r c; do
  [[ "$(code "$c")" == 0 ]] && ok "allows: $c" || fail "blocked by mistake: $c"
done <<'CMDS'
gh pr create --draft --base main --title x --body-file b.md
git push --force-with-lease origin factory/1-x && gh pr create --draft --base main --title x --body y
git push -u origin factory/1-main-menu
git diff origin/main...HEAD
grep -rn "gh pr merge" docs/
echo "never run git push origin main"
npm test
CMDS
[[ "$(SEATENV="" code "gh pr merge 12")" == 0 ]] && ok "your own session (no seat, no run) is untouched" || fail "guard blocked an unrelated session"
mkdir -p "$T/app/.factory/runs/live" && echo s1 > "$T/app/.factory/runs/live/orchestrator.session"
[[ "$(SEATENV="" code "gh pr merge 12")" == 2 ]] && ok "the running orchestrator's session is guarded" || fail "orchestrator session not guarded"
mcp="$(jq -nc --arg cwd "$T/app" '{session_id:"s1", cwd:$cwd, tool_name:"mcp__github__merge_pull_request", tool_input:{pull_number:1}}')"
set +e; python3 "$G" <<<"$mcp" 2>/dev/null; r=$?; set -e
[[ $r == 2 ]] && ok "blocks an MCP merge tool in the orchestrator session" || fail "MCP merge not blocked"
touch "$T/app/.factory/runs/live/ended"
[[ "$(SEATENV="" code "gh pr merge 12")" == 0 ]] && ok "guard releases when the run ends" || fail "guard did not release"

echo "== limits"
cat > "$RUN/state.json" <<'JSON'
{"run":"smoke","lanes":2,"budget":0,"tickets":[{"id":1,"flag":"LANE"},{"id":2,"flag":"LANE"},{"id":3,"flag":"READY"}]}
JSON
out="$("$BIN/alf-seat" acquire developer --run "$RUN" --ticket 3 || true)"
grep -q NO_FREE_LANE <<<"$out" && ok "a third lane is refused" || fail "third lane: $out"
jq '.tickets[1].flag="DONE" | .tickets[1].pr=9 | .budget=1' "$RUN/state.json" > "$RUN/s.tmp" && mv "$RUN/s.tmp" "$RUN/state.json"
out="$("$BIN/alf-seat" acquire developer --run "$RUN" --ticket 3 || true)"
grep -q BUDGET_SPENT <<<"$out" && ok "--budget is enforced when a lane is requested" || fail "budget: $out"
jq '.loop.lanes=3' .factory/config.json > c.tmp && mv c.tmp .factory/config.json
out="$("$BIN/alf-seat" acquire developer --run "$RUN" --ticket 3 2>&1 || true)"
grep -q "refused" <<<"$out" && ok "loop.lanes=3 is refused" || fail "lanes=3: $out"
jq '.loop.lanes=2' .factory/config.json > c.tmp && mv c.tmp .factory/config.json

echo "== a squashed-away sha does not jam a seat"
read -r seat path < <("$BIN/alf-seat" acquire reviewer)
git -C "$path" checkout -q -b tmp-x && echo z > "$path/z" && git -C "$path" add z && git -C "$path" commit -qm z
git -C "$path" push -q origin tmp-x 2>/dev/null
git -C "$path" checkout -q --detach && "$BIN/alf-seat" release "$seat" >/dev/null
# simulate a force-push that removes this sha from the remote
git -C "$path" push -q origin --delete tmp-x 2>/dev/null; git -C "$path" branch -q -D tmp-x; git -C "$T/app" fetch -q --prune origin
# finalize marks the seat at the commit it detached to; do the same here
# shellcheck source=bin/alf-lib.sh
(cd "$T/app" && source "$BIN/alf-lib.sh" && seat_mark "$seat" "$path")
read -r again _ < <("$BIN/alf-seat" acquire reviewer)
[[ "$again" == Reviewer ]] && ok "seat parked at its marked sha is reusable after a force-push" || fail "seat jammed: $again"

echo
echo "smoke: $pass checks passed"
