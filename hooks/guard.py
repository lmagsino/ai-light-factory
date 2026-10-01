#!/usr/bin/env python3
"""alf guard: a PreToolUse hook for Bash and MCP tools.

The line hands you a draft PR and stops. It never marks ready, never merges,
never approves, never opens a non-draft PR, never pushes to the integration
branch, and never force-pushes without a lease. This hook makes that a property
of the tools rather than a sentence in a prompt.

Two ways in. As a Claude Code hook (stdin JSON) it covers Claude dev-loop workers and
the session running /alf:dev-loop. As `guard.py --argv git ...` it is called by the
git and gh shims that alf-dispatch puts first on every worker's PATH, so the same
rules hold whatever agent CLI sits in the seat.

Hook scope: only dev-loop workers (ALF_SEAT is set by alf-dispatch) and the
session currently running /alf:dev-loop (its session id is in
.factory/runs/<run>/orchestrator.session until <run>/ended exists). Your own
sessions are untouched.

Commands are split into segments on && || ; | and newlines, and each `git` or
`gh` invocation is read token by token, so `grep "gh pr merge" docs/` is fine and
`git -C x push origin main` is not. Exit 2 blocks the call, and stderr goes to the model.
"""
import glob
import json
import os
import re
import shlex
import subprocess
import sys

SEPARATORS = {"&&", "||", ";", "|", "&", "(", ")"}
WRAPPERS = {"env", "command", "exec", "time", "nohup", "sudo", "xargs", "nice"}
GIT_OPTS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}
GH_OPTS_WITH_VALUE = {"-R", "--repo", "--hostname"}


def segments(command):
    """Yield token lists for each simple command. Falls back to a raw scan if quoting is broken."""
    for line in command.splitlines() or [command]:
        try:
            lex = shlex.shlex(line, posix=True, punctuation_chars=True)
            lex.whitespace_split = True
            tokens = list(lex)
        except ValueError:
            yield None, line
            continue
        seg = []
        for t in tokens:
            if t in SEPARATORS:
                if seg:
                    yield seg, line
                seg = []
            else:
                seg.append(t)
        if seg:
            yield seg, line


def nested(seg):
    """bash -c '...' / sh -c '...': return the inner command string."""
    if seg and os.path.basename(seg[0]) in {"bash", "sh", "zsh"} and "-c" in seg:
        i = seg.index("-c")
        if i + 1 < len(seg):
            return seg[i + 1]
    return None


def after_program(seg, name):
    """Return the tokens after the first token that is the program `name`, or None."""
    for i, t in enumerate(seg):
        if os.path.basename(t) == name:
            head = seg[:i]
            if all(re.fullmatch(r"\w+=.*", h) or os.path.basename(h) in WRAPPERS or h.startswith("-") for h in head):
                return seg[i + 1:]
    return None


def first_word(rest, opts_with_value):
    i = 0
    while i < len(rest):
        t = rest[i]
        if t in opts_with_value:
            i += 2
            continue
        if t.startswith("-"):
            i += 1
            continue
        return t, rest[i + 1:]
    return None, []


def check_git(rest, integ):
    sub, args = first_word(rest, GIT_OPTS_WITH_VALUE)
    if sub != "push":
        return None
    lease = any(a.startswith("--force-with-lease") or a.startswith("--force-if-includes") for a in args)
    for a in args:
        if a == "--force" or a.startswith("--force=") or a in ("--mirror", "--all"):
            return f"git push {a} is not allowed"
        if re.fullmatch(r"-[A-Za-z]*f[A-Za-z]*", a) and not lease:
            return "force-push without --force-with-lease"
        if not a.startswith("-") and a.startswith("+"):
            return "force-push via a +refspec"
    positional = [a for a in args if not a.startswith("-")]
    for a in positional[1:]:  # positional[0] is the remote
        target = a.split(":")[-1]
        if target in (integ, f"refs/heads/{integ}"):
            return f"pushing to the integration branch ({integ})"
    return None


def check_gh(rest):
    group, args = first_word(rest, GH_OPTS_WITH_VALUE)
    if group == "pr":
        sub, sargs = first_word(args, GH_OPTS_WITH_VALUE)
        if sub == "merge":
            return "merging is a human's call"
        if sub == "ready":
            return "marking a PR ready is a human's call"
        if sub == "review" and any(a in ("--approve", "-a") for a in sargs):
            return "approving is a human's call"
        if sub == "create" and not any(a in ("--draft", "-d") for a in sargs):
            return "the dev loop opens draft PRs only (add --draft)"
    if group == "api":
        joined = " ".join(args)
        if re.search(r"mergePullRequest|markPullRequestReadyForReview|enablePullRequestAutoMerge|"
                     r"/pulls/[^/\s]+/merge\b|APPROVE", joined):
            return "merge / ready / approve through the API is still a human's call"
        if re.search(r"/reviews\b", joined) and "--input" in args:
            return "submitting a review from a file is not allowed in the dev loop"
        if "graphql" in args and any(re.match(r"query=@", a) for a in args):
            return "GraphQL from a file cannot be checked; inline the query"
    return None


def check_command(command, integ, depth=0):
    for seg, raw in segments(command):
        if seg is None:  # unparseable: be conservative with the obvious cases
            if re.search(r"\bgh\b.*\bpr\b.*\b(merge|ready)\b|\bgit\b.*\bpush\b.*(--force\b|\s-f\b)", raw):
                return "command could not be parsed and looks like a merge or force-push"
            continue
        inner = nested(seg)
        if inner and depth < 3:
            r = check_command(inner, integ, depth + 1)
            if r:
                return r
        rest = after_program(seg, "git")
        if rest is not None:
            r = check_git(rest, integ)
            if r:
                return r
        rest = after_program(seg, "gh")
        if rest is not None:
            r = check_gh(rest)
            if r:
                return r
    return None


def check_mcp(name, tool_input):
    n = name.lower()
    if re.search(r"merge|ready_for_review|mark_.*ready|approve", n):
        return f"{name} is a human's call"
    if str(tool_input.get("event", "")).upper() == "APPROVE":
        return "approving is a human's call"
    return None


def git_common_dir(cwd):
    try:
        out = subprocess.run(["git", "-C", cwd, "rev-parse", "--path-format=absolute", "--git-common-dir"],
                             capture_output=True, text=True, timeout=5)
        return os.path.dirname(out.stdout.strip()) if out.returncode == 0 else None
    except Exception:
        return None


def in_scope(data, root):
    if os.environ.get("ALF_SEAT"):
        return True
    sid = data.get("session_id")
    if not sid or not root:
        return False
    for f in glob.glob(os.path.join(root, ".factory", "runs", "*", "orchestrator.session")):
        if os.path.exists(os.path.join(os.path.dirname(f), "ended")):
            continue
        try:
            if sid in open(f, encoding="utf-8").read().split():
                return True
        except OSError:
            pass
    return False


def integration_branch(cwd):
    root = git_common_dir(cwd)
    if root and os.path.exists(os.path.join(root, ".factory", "config.json")):
        try:
            return json.load(open(os.path.join(root, ".factory", "config.json")))["repo"]["integration_branch"] or "main", root
        except Exception:
            pass
    return "main", root


def argv_mode(argv):
    """Called by the git/gh shims that every dev-loop worker gets on its PATH, whatever agent it runs."""
    prog, args = argv[0], argv[1:]
    integ, _ = integration_branch(os.getcwd())
    reason = check_command(shlex.join([prog] + args), integ)
    if reason:
        print(f"alf guard: blocked - {reason}. The line stops at a draft PR; "
              f"record what you would have done in the PR body instead.", file=sys.stderr)
        return 2
    return 0


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--argv":
        return argv_mode(sys.argv[2:])
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    name = data.get("tool_name", "")
    tool_input = data.get("tool_input") or {}
    cwd = data.get("cwd") or "."

    if name == "Bash":
        command = tool_input.get("command") or ""
        if not re.search(r"\b(git|gh)\b", command):  # fast path
            return 0
        integ, root = integration_branch(cwd)
        reason = check_command(command, integ)
    elif name.startswith("mcp__"):
        reason = check_mcp(name, tool_input)
        root = git_common_dir(cwd) if reason else None
    else:
        return 0

    if not reason or not in_scope(data, root):
        return 0
    print(f"alf guard: blocked - {reason}. The line stops at a draft PR; "
          f"record what you would have done in the PR body instead.", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
