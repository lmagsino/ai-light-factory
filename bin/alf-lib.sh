#!/usr/bin/env bash
# Shared helpers for alf scripts. Sourced, never executed.
# shellcheck disable=SC2034

set -euo pipefail

ALF_ROOT="${ALF_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ALF_VERSION="0.1.0"

die()  { printf 'alf: %s\n' "$*" >&2; exit 1; }
warn() { printf 'alf: %s\n' "$*" >&2; }
need() { local c; for c in "$@"; do command -v "$c" >/dev/null 2>&1 || die "missing dependency: $c"; done; }

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || die "not inside a git repository"
}

# The main checkout, even when called from inside a seat worktree.
main_root() {
  local common
  common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || die "not inside a git repository"
  dirname "$common"
}

repo_name() { basename "$(main_root)"; }

config_path() { printf '%s/.factory/config.json' "$(main_root)"; }

# cfg '.band.lanes' [default]
cfg() {
  local f v
  f="$(config_path)"
  [[ -f "$f" ]] || die "no .factory/config.json - run /alf:setup first"
  v="$(jq -r "($1) // empty" "$f")"
  if [[ -z "$v" && $# -ge 2 ]]; then v="$2"; fi
  printf '%s' "$v"
}

worktree_root() {
  local tmpl
  tmpl="$(cfg '.band.worktree_root' '../{repo}.alf')"
  tmpl="${tmpl//\{repo\}/$(repo_name)}"
  case "$tmpl" in
    /*) printf '%s' "$tmpl" ;;
    *)  (cd "$(main_root)" && mkdir -p "$tmpl" && cd "$tmpl" && pwd) ;;
  esac
}

ledger_path() { printf '%s/.factory/ledger.jsonl' "$(main_root)"; }

# Append one JSON object (compact) to the ledger.
ledger_append() {
  local line="$1" f
  f="$(ledger_path)"
  mkdir -p "$(dirname "$f")"
  printf '%s\n' "$(jq -c . <<<"$line")" >>"$f"
}

# Seat naming. Base seat is the role name; the overflow seat is <Role>-2.
# There is no -3: two is the ceiling, not a starting point.
role_title() {
  case "$1" in
    developer) echo Developer ;;
    reviewer)  echo Reviewer ;;
    guardian)  echo Guardian ;;
    verifier)  echo Verifier ;;
    *) die "unknown role: $1 (developer|reviewer|guardian|verifier)" ;;
  esac
}

role_cap() {
  case "$1" in
    verifier) echo 1 ;;   # it binds the app's port; a second one waits
    *)        echo 2 ;;
  esac
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }   # bash 3.2 has no ${x,,}

seat_role() { # Seat name -> role, case-insensitive (one base seat may be lowercase on disk)
  local s
  s="$(lower "$1")"
  s="${s%-2}"
  case "$s" in
    developer|reviewer|guardian|verifier) echo "$s" ;;
    *) echo "" ;;
  esac
}

is_base_seat() {
  local s
  s="$(lower "$1")"
  [[ "$s" == developer || "$s" == reviewer || "$s" == guardian || "$s" == verifier ]]
}

# True when a worktree holds work that exists nowhere else.
has_unpushed() {
  local p="$1"
  if git -C "$p" rev-parse --verify --quiet '@{u}' >/dev/null 2>&1; then
    [[ -n "$(git -C "$p" log --oneline '@{u}..HEAD' 2>/dev/null)" ]]
  else
    [[ -n "$(git -C "$p" log --oneline HEAD --not --remotes 2>/dev/null)" ]]
  fi
}

is_dirty() {
  [[ -n "$(git -C "$1" status --porcelain 2>/dev/null)" ]]
}

pid_alive() { [[ -n "${1:-}" && "${1:-}" != null ]] && kill -0 "$1" 2>/dev/null; }

# Seats remember the commit they were parked at. A detached HEAD at that commit is
# clean even when force-pushes have since removed it from every remote; only work a
# worker made after that point (or on a branch) counts as unpushed.
seat_home_dir() { printf '%s/.home' "$(worktree_root)"; }

seat_mark() { # Seat path
  mkdir -p "$(seat_home_dir)"
  git -C "$2" rev-parse HEAD >"$(seat_home_dir)/$1"
}

seat_unpushed() { # Seat path -> 0 when the seat holds work that exists nowhere else
  local br mark
  br="$(git -C "$2" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  if [[ -n "$br" ]]; then has_unpushed "$2"; return; fi
  mark="$(cat "$(seat_home_dir)/$1" 2>/dev/null || true)"
  [[ -n "$mark" && "$(git -C "$2" rev-parse HEAD)" == "$mark" ]] && return 1
  has_unpushed "$2"
}

# Hash of the dependency lockfiles, so a seat re-runs commands.setup only when they change.
deps_hash() { # path
  local f files=()
  for f in package-lock.json npm-shrinkwrap.json yarn.lock pnpm-lock.yaml bun.lockb Gemfile.lock \
           poetry.lock uv.lock Pipfile.lock requirements.txt go.sum Cargo.lock composer.lock mix.lock; do
    [[ -f "$1/$f" ]] && files+=("$1/$f")
  done
  if ((${#files[@]})); then cat "${files[@]}" | git hash-object --stdin; else echo none; fi
}
