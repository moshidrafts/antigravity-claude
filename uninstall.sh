#!/usr/bin/env bash
set -e

echo "=========================================================================="
echo "             UNINSTALL ANTIGRAVITY PROTOCOL SUITE                         "
echo "=========================================================================="
echo "This will safely remove Antigravity skills, configuration, and prompt caching."
echo "(Your personal custom skills outside this suite will NOT be touched)"
echo ""

read -p "Are you sure you want to proceed? (y/N): " confirm
if [[ "$confirm" != [yY] ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
DISABLED_DIR="$CLAUDE_DIR/skills-disabled"

ALL_SKILLS=(
    "antigravity"
    "antigravity-planner"
    "frontend-design"
    "test-driven-development"
    "systematic-debugging"
    "verification-before-completion"
    "web-artifacts-builder"
    "xlsx"
    "pdf"
    "docx"
)

echo "[1/4] Removing Antigravity skills..."
for s in "${ALL_SKILLS[@]}"; do
    rm -rf "$SKILLS_DIR/$s" 2>/dev/null || true
    rm -rf "$DISABLED_DIR/$s" 2>/dev/null || true
    echo "  -> Removed: $s"
done

echo "[2/4] Removing CLAUDE.md..."
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    if grep -q "ANTIGRAVITY OPERATING SYSTEM DIRECTIVE" "$CLAUDE_DIR/CLAUDE.md"; then
        rm -f "$CLAUDE_DIR/CLAUDE.md"
        echo "  -> Antigravity CLAUDE.md removed."
    fi
fi

echo "[3/4] Clearing prompt caching variables..."
sed -i '' '/ENABLE_PROMPT_CACHING_1H/d' "$HOME/.bashrc" 2>/dev/null || true
sed -i '' '/ENABLE_PROMPT_CACHING_1H/d' "$HOME/.zshrc" 2>/dev/null || true

echo "[4/4] Removing config..."
rm -f "$CLAUDE_DIR/antigravity.json"

echo ""
echo "[SUCCESS] Antigravity Suite uninstalled cleanly."
