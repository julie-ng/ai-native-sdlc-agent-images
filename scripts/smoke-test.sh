#!/bin/sh
set -eu
role="${1:-}"
case "$role" in
  ''|planner|coder|reviewer) ;;
  *) echo 'Usage: agent-image-smoke-test [planner|coder|reviewer]' >&2; exit 2 ;;
esac
# The inherited smoke recipe calls this without arguments in every image.
if [ -z "$role" ]; then
  for candidate in planner coder reviewer; do
    if [ -e "/recipes/$candidate/recipe.yaml" ]; then
      test -z "$role" || { echo 'FAIL: multiple role recipes installed' >&2; exit 1; }
      role="$candidate"
    fi
  done
fi
test "$(id -un)" = goose
test "$(id -u)" = 1000
test -w /workspace
test -w "$HOME/.local/state/goose/logs"
test -w "$HOME/.local/share/goose"
test ! -f "$HOME/.config/goose/config.yaml"
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  echo 'FAIL: runtime user can sudo' >&2
  exit 1
fi
goose --version
python3 --version
python3 -c 'import bz2, ctypes, lzma, readline, sqlite3, ssl; print("Python shared libraries: OK")'
uv --version
node --version
npm --version
tsc --version
tsx --version
gh --version
jq --version
rg --version
git --version
gpg --version
python3 -m venv /tmp/agent-smoke-venv
/tmp/agent-smoke-venv/bin/python -m pip --version
rm -rf /tmp/agent-smoke-venv
npm --cache /tmp/agent-smoke-npm-cache cache verify
rm -rf /tmp/agent-smoke-npm-cache
goose recipe validate /recipes/smoke-test.yaml
for candidate in planner coder reviewer; do
  if [ "$candidate" = "$role" ]; then
    goose recipe validate "/recipes/$candidate/recipe.yaml"
  else
    test ! -e "/recipes/$candidate/recipe.yaml"
  fi
done
echo 'Image smoke checks passed (no model call).'
