#!/usr/bin/env bash
set -euo pipefail

COMMIT_TYPE="${1:-ai-defined}"
COMMITS_TO_SUGGEST=4
COMMIT_DIR=".git/lazygit-ai-commit"

diff=$(git diff --cached)
if [ -z "$diff" ]; then
  echo "No changes in staging. Add changes first." >&2
  exit 1
fi

mkdir -p "$COMMIT_DIR"
rm -f "$COMMIT_DIR"/candidate-*.txt

PROMPT=$(
  cat <<EOF
You are an expert at writing Git commits. Your job is to write commit messages that follow the Conventional Commits format, each with a subject line and a short body paragraph.
The user has selected: $COMMIT_TYPE

Your task is to:
1. Analyze the code changes
2. Determine the most appropriate commit type if user selected ai-defined
3. Determine an appropriate scope, component, or area affected
4. Decide if this is a breaking change
5. Write a clear, concise commit subject
6. Write a short body (1-3 sentences) explaining WHAT changed and WHY, in plain prose

Available commit types:
- feat: A new feature
- fix: A bug fix
- docs: Documentation only changes
- style: Changes that do not affect the meaning of the code
- refactor: A code change that neither fixes a bug nor adds a feature
- perf: A code change that improves performance
- test: Adding missing tests or correcting existing tests
- build: Changes that affect the build system or external dependencies
- ci: Changes to CI configuration files and scripts
- chore: Other changes that do not modify src or test files
- revert: Reverts a previous commit

Follow these guidelines:
- Subject structure: <type>(<scope>): <description>
- If user selected ai-defined, analyze the changes and pick the most suitable type
- If user selected a specific type, use that type: $COMMIT_TYPE
- Add scope in parentheses if applicable, for example auth, api, ui, config
- Use exclamation mark after type or scope for breaking changes: type(scope)!: description
- Use lowercase for description except proper nouns
- Use imperative mood: add, not added
- Keep subject under 50 characters when possible
- No period at the end of the subject

IMPORTANT OUTPUT FORMAT:
- Generate exactly $COMMITS_TO_SUGGEST candidate commit messages
- Before EACH candidate, output a line containing exactly: ===CANDIDATE===
- Each candidate is: the subject line, then one blank line, then the body paragraph
- Do not number the candidates
- Do not use markdown or code blocks anywhere in the output
- Do not add any commentary before, between, or after the candidates

Previous commits for context:
$(git log --oneline -10)

Changes to analyze:
$(git diff --cached --stat)

$diff
EOF
)

RAW=$(opencode run --format json --model=opencode-go/mimo-v2.5 --variant=none "$PROMPT" |
  jq -j 'select(.type=="text") | .part.text? // empty')

echo "$RAW" | awk -v dir="$COMMIT_DIR" '
  BEGIN { file = "/dev/null" }
  /^===CANDIDATE===$/ { n++; file = dir "/candidate-" n ".txt"; next }
  { print > file }
'

shopt -s nullglob
for f in "$COMMIT_DIR"/candidate-*.txt; do
  [ -s "$f" ] || continue
  subject=$(head -n1 "$f")
  printf '%s|||%s\n' "$subject" "$f"
done
