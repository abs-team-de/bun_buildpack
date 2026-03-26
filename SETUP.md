# GitHub CLI Setup (Debian/Ubuntu)

## Install

```bash
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) && sudo mkdir -p -m 755 /etc/apt/keyrings && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && sudo apt update && sudo apt install gh -y
```

## Authenticate

```bash
gh auth login
```

## Verify

```bash
gh auth status
```

## Set up branch protection for master

```bash
gh api repos/abs-team-de/bun_buildpack/branches/master/protection \
  -X PUT --input - <<'EOF'
{
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "enforce_admins": true,
  "restrictions": null,
  "required_status_checks": null
}
EOF
```
