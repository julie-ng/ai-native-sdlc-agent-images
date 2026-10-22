#!/bin/sh
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  bash ca-certificates curl git gnupg jq ripgrep \
  libstdc++6 libgcc-s1 libbz2-1.0 libffi8 libexpat1 liblzma5 \
  libsqlite3-0 libreadline8 zlib1g libssl3
rm -rf /var/lib/apt/lists/*
ldconfig

# Release sources: https://github.com/cli/cli/releases
arch="$(dpkg --print-architecture)"
curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${arch}.tar.gz" -o /tmp/gh.tar.gz
tar -xzf /tmp/gh.tar.gz -C /tmp
install -m 0755 "/tmp/gh_${GH_VERSION}_linux_${arch}/bin/gh" /usr/local/bin/gh
rm -rf /tmp/gh.tar.gz "/tmp/gh_${GH_VERSION}_linux_${arch}"

python3 -m pip install --no-cache-dir "uv==${UV_VERSION}"
npm install --global --cache /tmp/agent-npm-cache \
  "typescript@${TYPESCRIPT_VERSION}" "tsx@${TSX_VERSION}"
rm -rf /tmp/agent-npm-cache
