#!/usr/bin/env bash
# Restructuring test run.
# usage: bash run.sh <sample> <run-name> [noskill|skill] [model]
# Copies samples/<sample> to runs/<run-name>, plants the decoy ApiClient, runs a
# headless claude session there with the pressure scenario, then records
# analyze / test / git results next to the run directory.
set -uo pipefail

WORK="/c/Users/Katyayani/Documents/flutter/mymali-architecture-skill/dev"
SAMPLE="$1"
RUN="$2"
MODE="${3:-noskill}"
MODEL="${4:-claude-opus-5-5}"
SRC="$WORK/samples/$SAMPLE"
DST="$WORK/runs/$RUN"
OUT="$WORK/runs/$RUN.out"

rm -rf "$DST" "$OUT"
mkdir -p "$DST" "$OUT"
(cd "$SRC" && tar --exclude=./build --exclude=./.dart_tool -cf - .) | (cd "$DST" && tar -xf -)

cd "$DST" || exit 1
if [ ! -d .git ]; then
  git init -q && git add -A && git -c user.name=fixture -c user.email=fixture@example.com commit -qm "sample fixture"
fi
# The sunk-cost decoy: a half-done Dio wrapper with the wrong name.
mkdir -p lib/core/network
cp "$WORK/harness/decoy_api_client.dart" lib/core/network/api_client.dart
flutter pub add dio >"$OUT/pub_add.txt" 2>&1
flutter pub get >"$OUT/pub_get.txt" 2>&1
git add -A >/dev/null 2>&1
git -c user.name=fixture -c user.email=fixture@example.com commit -qm "WIP: shared api client" >/dev/null 2>&1
git rev-parse HEAD > "$OUT/base_commit.txt"

PROMPT="$(cat "$WORK/harness/scenario.md")"
if [ "$MODE" = "skill" ]; then
  PROMPT="$(printf 'Use the applying-mymali-architecture skill for this task.\n\n%s' "$PROMPT")"
  # A project-local copy of the skill, kept out of the app's git history.
  mkdir -p .claude/skills
  cp -r "$WORK/../applying-mymali-architecture" .claude/skills/
  echo ".claude/" >> .git/info/exclude
fi
printf '%s' "$PROMPT" > "$OUT/prompt.txt"

echo "start $(date -Iseconds) sample=$SAMPLE mode=$MODE model=$MODEL" > "$OUT/meta.txt"
env -u CLAUDECODE claude -p "$PROMPT" --output-format json --dangerously-skip-permissions --model "$MODEL" \
  > "$OUT/claude.json" 2> "$OUT/claude.err"
echo "claude_exit=$? end $(date -Iseconds)" >> "$OUT/meta.txt"

{
  echo "== analyze"; flutter analyze 2>&1 | tail -40
  echo "== test"; flutter test 2>&1 | tail -30
  echo "== git log"; git log --oneline | head -10
  echo "== changed files vs base"; git diff --stat "$(cat "$OUT/base_commit.txt")" HEAD 2>/dev/null | tail -80
  echo "== uncommitted"; git status --short | head -80
  echo "== tree"; find lib test -type f | sort
} > "$OUT/post.txt" 2>&1
echo "done" >> "$OUT/meta.txt"
