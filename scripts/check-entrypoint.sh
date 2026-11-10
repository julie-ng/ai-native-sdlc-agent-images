#!/bin/sh
set -eu
check_dir=$(mktemp -d)
trap 'gpgconf --homedir "$check_dir/generator" --kill all 2>/dev/null || :; rm -rf "$check_dir"' EXIT
export HOME="$check_dir/home"
mkdir -m 700 "$HOME" "$check_dir/generator" "$check_dir/secrets"
unset GH_TOKEN AI_GATEWAY_API_KEY GIT_USER_NAME GIT_USER_EMAIL GNUPGHOME
export AGENT_SECRETS_DIR="$check_dir/missing"
/usr/local/bin/agent-entrypoint sh -eu -c '
  test -z "${GH_TOKEN+x}"
  test -z "${AI_GATEWAY_API_KEY+x}"
  test ! -e "$HOME/.gitconfig"
'
# Runtime values survive when no file is mounted.
AI_GATEWAY_API_KEY=existing /usr/local/bin/agent-entrypoint sh -eu -c 'test "$AI_GATEWAY_API_KEY" = existing'

gpg --homedir "$check_dir/generator" --batch --pinentry-mode loopback --passphrase '' \
  --quick-generate-key 'Offline Test <offline@example.invalid>' ed25519 sign 0 >/dev/null 2>&1
expected=$(gpg --homedir "$check_dir/generator" --with-colons --list-secret-keys 2>/dev/null | awk -F: '$1 == "fpr" {print $10; exit}')
gpg --homedir "$check_dir/generator" --batch --armor --export-secret-keys > "$check_dir/secrets/agent-gpg-private-key"
printf '%s\n' fake-gateway > "$check_dir/secrets/vercel-ai-gateway-api-key"
printf '%s\n' fake-github > "$check_dir/secrets/julieio-goose-github-pat"
export AGENT_SECRETS_DIR="$check_dir/secrets" GIT_USER_NAME='Offline Test' GIT_USER_EMAIL=offline@example.invalid
export expected
/usr/local/bin/agent-entrypoint sh -eu -c '
  trap '\''gpgconf --kill all'\'' EXIT
  test "$AI_GATEWAY_API_KEY" = fake-gateway
  test "$GH_TOKEN" = fake-github
  test "$(stat -c %a "$GNUPGHOME")" = 700
  test "$(git config --global user.signingkey)" = "$expected"
  test "$(git config --global commit.gpgsign)" = true
  git config --global --get-all credential.https://github.com.helper | rg -q "gh auth git-credential"
  # Credentials remain in the process environment, not the git config.
  ! rg -q "fake-github|fake-gateway" "$HOME/.gitconfig"
  git init -q "$HOME/repo"
  cd "$HOME/repo"
  git commit -q --allow-empty -m "Offline signed commit"
  git verify-commit HEAD >/dev/null 2>&1
  test "$(git log -1 --format=%ae)" = offline@example.invalid
'
printf '%s\n' invalid > "$check_dir/secrets/agent-gpg-private-key"
if /usr/local/bin/agent-entrypoint true > "$check_dir/error" 2>&1; then
  echo 'FAIL: invalid signing key accepted' >&2
  exit 1
fi
! rg -q 'invalid|fake-github|fake-gateway' "$check_dir/error"
echo 'Entrypoint checks passed (fake secrets, offline signed commit).'
