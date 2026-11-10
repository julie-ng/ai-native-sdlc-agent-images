#!/bin/sh
set -eu

secrets_dir=${AGENT_SECRETS_DIR:-/mnt/agent-secrets}
if [ -f "$secrets_dir/vercel-ai-gateway-api-key" ]; then
  AI_GATEWAY_API_KEY=$(cat "$secrets_dir/vercel-ai-gateway-api-key")
  export AI_GATEWAY_API_KEY
fi
if [ -f "$secrets_dir/julieio-goose-github-pat" ]; then
  GH_TOKEN=$(cat "$secrets_dir/julieio-goose-github-pat")
  export GH_TOKEN
  # Explicit hostname keeps setup offline; the helper reads GH_TOKEN at use time.
  gh auth setup-git --hostname github.com
fi

if [ -n "${GIT_USER_NAME:-}" ]; then
  git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
fi
if [ -f "$secrets_dir/agent-gpg-private-key" ]; then
  # A fresh private directory avoids selecting a key left by an earlier run.
  previous_umask=$(umask)
  umask 077
  GNUPGHOME=$(mktemp -d "$HOME/.gnupg-agent.XXXXXX")
  umask "$previous_umask"
  export GNUPGHOME
  # Suppress GPG diagnostics: malformed input must not leak mounted contents.
  if ! gpg --batch --import "$secrets_dir/agent-gpg-private-key" >/dev/null 2>&1; then
    echo 'Failed to import agent signing key' >&2
    exit 1
  fi
  fingerprint=$(gpg --batch --with-colons --list-secret-keys 2>/dev/null |
    awk -F: '$1 == "fpr" {print $10; exit}')
  if [ -z "$fingerprint" ]; then
    echo 'Agent signing key contains no private key' >&2
    exit 1
  fi
  git config --global user.signingkey "$fingerprint"
  git config --global commit.gpgsign true
fi

exec "$@"
