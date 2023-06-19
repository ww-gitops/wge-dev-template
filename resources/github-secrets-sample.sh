GITHUB_CLIENT_ID=... # Github Organisation Client ID
GITHUB_CLIENT_SECRET=... # Github Organisation Client Secret
WGE_DEX_CLIENT_SECRET="$(date +%s | sha256sum | base64 | head -c 10)"
VAULT_DEX_CLIENT_SECRET="$(date +%s | sha256sum | base64 | head -c 10)"

export GITHUB_TOKEN=... # write access token

export GITLAB_TOKEN_READ=... # read access token