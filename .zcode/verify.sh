#!/bin/bash
# verify.sh — Runs only the relevant checks based on recently modified files.
# Called by zcode PostToolUse hook after Edit/Write.
# Exit 0 = pass, non-zero = fail (agent must fix)

set -e

cd "${ZCODE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

RECENT_PY=$(find . -name "*.py" -mmin -0.5 -not -path "./.venv/*" -not -path "./node_modules/*" -not -path "./__pycache__/*" 2>/dev/null | head -1)
RECENT_TS=$(find . \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -mmin -0.5 -not -path "./node_modules/*" -not -path "./.next/*" 2>/dev/null | head -1)

RAN=false

if [ -n "$RECENT_PY" ]; then
  echo "=== Python changed → ruff + pyright + pytest ==="
  uv run ruff check .
  uv run pyright
  uv run pytest --tb=short -q
  RAN=true
fi

if [ -n "$RECENT_TS" ]; then
  echo "=== Frontend changed → biome + tsc + vitest ==="
  bunx biome ci .
  bunx tsc --noEmit
  bun run test
  RAN=true
fi

if [ "$RAN" = false ]; then
  echo "No code files modified recently — skipping checks"
fi

echo "✓ Relevant checks passed"
