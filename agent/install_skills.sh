#!/bin/sh

set -eu

if command -v openspec >/dev/null 2>&1 && [ ! -f /root/.config/openspec/config.json ]; then
    cat > /root/.config/openspec/config.json << 'EOF'
{
  "profile": "custom",
  "delivery": "skills",
  "workflows": [
    "propose", "explore", "new", "continue",
    "apply", "ff", "sync", "archive",
    "bulk-archive", "verify", "onboard"
  ]
}
EOF

    tmpdir=$(mktemp -d)
    openspec init --profile custom --tools opencode --force "$tmpdir"
    cp -r "$tmpdir/.opencode/skills/." /root/.agents/skills/
    rm -rf "$tmpdir"
fi

# Install Zillaforge Skill
tmp=$(mktemp -d) 
git clone https://github.com/Zillaforge/skills.git "$tmp/skills"
cp -a -- "$tmp"/skills/zillaforge-* ~/.agents/skills/
rm -rf "$tmp"

# Install officecli skill
officecli install

# Install ELI5 (Explain Like I Am 5)
#
tmp=$(mktemp -d)
git clone https://github.com/DreambigOu/ELI5.git "$tmp/skills"
cp -a -- "$tmp"/skills/skills/eli5 ~/.agents/skills/
rm -rf "$tmp"
