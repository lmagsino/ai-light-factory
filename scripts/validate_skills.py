#!/usr/bin/env python3
"""Validate every skills/*/SKILL.md against the Agent Skills spec (agentskills.io).

Checks: frontmatter present; name matches directory, 1-64 chars of [a-z0-9-],
no leading/trailing/double hyphen; description 1-1024 chars; body under 500
lines; portable skills use only spec fields. Stdlib only (no PyYAML): the
frontmatter is parsed as simple `key: value` lines plus nested blocks.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SPEC_FIELDS = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
CLAUDE_FIELDS = {"disable-model-invocation", "argument-hint", "arguments", "user-invocable", "when_to_use",
                 "model", "effort", "context", "agent", "paths", "hooks", "shell", "disallowed-tools", "background"}
PORTABLE = {"build", "review", "guardian"}  # may run under Codex

errors = []


def err(path, msg):
    errors.append(f"{path.relative_to(ROOT)}: {msg}")


def parse_frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        return None, text
    fields, current = {}, None
    for line in m.group(1).splitlines():
        if not line.strip():
            continue
        if line[0] in " \t":
            if current:
                fields[current] += "\n" + line
            continue
        k, _, v = line.partition(":")
        current = k.strip()
        fields[current] = v.strip().strip('"').strip("'")
    return fields, m.group(2)


for skill in sorted((ROOT / "skills").glob("*/SKILL.md")):
    d = skill.parent.name
    fm, body = parse_frontmatter(skill.read_text(encoding="utf-8"))
    if fm is None:
        err(skill, "missing YAML frontmatter")
        continue
    name = fm.get("name", "")
    if name != d:
        err(skill, f"name '{name}' must match directory '{d}'")
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name or "") or len(name) > 64:
        err(skill, f"name '{name}' must be 1-64 chars of a-z, 0-9 and single hyphens")
    desc = fm.get("description", "")
    if not (1 <= len(desc) <= 1024):
        err(skill, f"description length {len(desc)} must be 1-1024")
    unknown = set(fm) - SPEC_FIELDS - CLAUDE_FIELDS
    if unknown:
        err(skill, f"unknown frontmatter fields: {sorted(unknown)}")
    if d in PORTABLE and set(fm) - SPEC_FIELDS:
        err(skill, f"portable skill uses non-spec fields: {sorted(set(fm) - SPEC_FIELDS)}")
    if len(body.splitlines()) > 500:
        err(skill, f"body is {len(body.splitlines())} lines; keep under 500 and move detail to references/")
    for ref in re.findall(r"\$\{CLAUDE_SKILL_DIR\}/([\w./-]+)", body):
        if not (skill.parent / ref).exists():
            err(skill, f"references missing file {ref}")
    for ref in re.findall(r"\$\{CLAUDE_PLUGIN_ROOT\}/([\w./-]+)", body):
        if not (ROOT / ref).exists():
            err(skill, f"references missing plugin file {ref}")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print(f"ok: {len(list((ROOT / 'skills').glob('*/SKILL.md')))} skills valid")
