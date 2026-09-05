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
CATALOG_DIR="$CLAUDE_DIR/skills-catalog"
BIN_DIR="$CLAUDE_DIR/bin"

ALL_SKILLS=(
    "antigravity"
    "antigravity-planner"
    "caveman"
    "session-metrics"
    "session-report"
    "graphify"
    "frontend-design"
    "test-driven-development"
    "systematic-debugging"
    "verification-before-completion"
    "web-artifacts-builder"
    "xlsx"
    "pdf"
    "docx"
)

echo "[1/5] Removing Antigravity skills and catalog..."
for s in "${ALL_SKILLS[@]}"; do
    rm -rf "$SKILLS_DIR/$s" 2>/dev/null || true
    rm -rf "$DISABLED_DIR/$s" 2>/dev/null || true
done
rm -rf "$CATALOG_DIR" 2>/dev/null || true

echo "[2/5] Restoring CLAUDE.md..."
if [ -f "$CLAUDE_DIR/CLAUDE.md.bak" ]; then
    mv -f "$CLAUDE_DIR/CLAUDE.md.bak" "$CLAUDE_DIR/CLAUDE.md"
    echo "  -> Restored original CLAUDE.md from backup."
elif [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    if grep -q "ANTIGRAVITY OPERATING SYSTEM DIRECTIVE" "$CLAUDE_DIR/CLAUDE.md"; then
        rm -f "$CLAUDE_DIR/CLAUDE.md"
        echo "  -> Antigravity CLAUDE.md removed."
    fi
fi

echo "[3/5] Cleaning up hooks and launchers..."
rm -f "$CLAUDE_DIR/RTK.md" 2>/dev/null || true
rm -f "$BIN_DIR/agy-settings" 2>/dev/null || true
rm -f "$BIN_DIR/settings.sh" 2>/dev/null || true

echo "[4/5] Clearing prompt caching variables..."
remove_line() {
    local pattern="$1"
    local file="$2"
    [ -f "$file" ] || return 0
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$pattern" "$file" 2>/dev/null || true
    else
        sed -i "$pattern" "$file" 2>/dev/null || true
    fi
}
remove_line '/ENABLE_PROMPT_CACHING_1H/d' "$HOME/.bashrc"
remove_line '/ENABLE_PROMPT_CACHING_1H/d' "$HOME/.zshrc"

echo "[5/5] Removing config..."
rm -f "$CLAUDE_DIR/antigravity.json"

echo ""
echo "[SUCCESS] Antigravity Suite uninstalled cleanly."
