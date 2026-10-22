#!/bin/sh
set -eu
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
echo 'Image smoke checks passed (no model call).'
