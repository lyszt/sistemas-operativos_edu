#!/usr/bin/env bash
# Spanish grammar/style check on a compiled PDF, via the public LanguageTool API.
# Usage: lint-grammar.sh <path-to-pdf>
set -euo pipefail

PDF="${1:?usage: lint-grammar.sh <path-to-pdf>}"
LANG_CODE="es"
API_URL="https://api.languagetool.org/v2/check"

command -v pdftotext >/dev/null || { echo "pdftotext not found (poppler-utils)" >&2; exit 2; }
command -v curl      >/dev/null || { echo "curl not found" >&2; exit 2; }
command -v jq        >/dev/null || { echo "jq not found" >&2; exit 2; }
[ -f "$PDF" ] || { echo "PDF not found: $PDF (run 'make build' first)" >&2; exit 2; }

TEXT="$(pdftotext -layout "$PDF" -)"
[ -n "$TEXT" ] || { echo "No text extracted from $PDF" >&2; exit 2; }

RESPONSE="$(curl -sS --fail \
  --data-urlencode "text=$TEXT" \
  --data-urlencode "language=$LANG_CODE" \
  --data-urlencode "disabledRules=WHITESPACE_RULE" \
  "$API_URL")"

MATCH_COUNT="$(jq '.matches | length' <<<"$RESPONSE")"

if [ "$MATCH_COUNT" -eq 0 ]; then
  echo "No grammar/style issues found."
  exit 0
fi

echo "Found $MATCH_COUNT issue(s):"
echo

jq -r '
  .matches[] |
  "- \(.message)\n  context: ...\(.context.text)...\n  suggestions: \([.replacements[].value] | join(", "))\n"
' <<<"$RESPONSE"

exit 1
