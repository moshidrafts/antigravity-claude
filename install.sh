#!/usr/bin/env bash
set -e

clear
echo "=========================================================================="
echo "               ANTIGRAVITY PROTOCOL SUITE FOR CLAUDE                      "
echo "=========================================================================="

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
CATALOG_DIR="$CLAUDE_DIR/skills-catalog"
BIN_DIR="$CLAUDE_DIR/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SKILLS="$SCRIPT_DIR/skills"

mkdir -p "$CLAUDE_DIR" "$SKILLS_DIR" "$CATALOG_DIR" "$BIN_DIR"

echo -n "[1/6] Deploying 12 skills to $SKILLS_DIR and catalog... "
if [ -d "$LOCAL_SKILLS" ]; then
    cp -r "$LOCAL_SKILLS"/* "$SKILLS_DIR/"
    cp -r "$LOCAL_SKILLS"/* "$CATALOG_DIR/"
fi
echo "[DONE]"

echo "[2/6] Configuring global CLAUDE.md..."
CLAUDE_MD_DEST="$CLAUDE_DIR/CLAUDE.md"
CLAUDE_MD_SRC="$SCRIPT_DIR/CLAUDE.md"

if [ -f "$CLAUDE_MD_DEST" ]; then
    if ! grep -q "ANTIGRAVITY OPERATING SYSTEM DIRECTIVE" "$CLAUDE_MD_DEST"; then
        echo ""
        echo "  [!] An existing CLAUDE.md was detected at: $CLAUDE_MD_DEST"
        echo "      How would you like to handle this?"
        echo "      [O] Overwrite (recommended - backs up existing file to CLAUDE.md.bak)"
        echo "      [A] Append Antigravity Protocol to the end of existing file"
        echo "      [C] Cancel / Exit setup without modifying CLAUDE.md"
        read -p "      Select an option (O/A/C): " mdChoice
        case "$mdChoice" in
            [aA])
                cp "$CLAUDE_MD_DEST" "$CLAUDE_MD_DEST.bak"
                echo "" >> "$CLAUDE_MD_DEST"
                cat "$CLAUDE_MD_SRC" >> "$CLAUDE_MD_DEST"
                echo "  -> Antigravity appended to existing CLAUDE.md (backup saved to CLAUDE.md.bak)"
                ;;
            [cC])
                echo "Setup cancelled. No modifications were made to CLAUDE.md."
                exit 0
                ;;
            *)
                cp "$CLAUDE_MD_DEST" "$CLAUDE_MD_DEST.bak"
                cp -f "$CLAUDE_MD_SRC" "$CLAUDE_MD_DEST"
                echo "  -> CLAUDE.md overwritten (original backed up to CLAUDE.md.bak)"
                ;;
        esac
    else
        cp -f "$CLAUDE_MD_SRC" "$CLAUDE_MD_DEST"
        echo "  -> Antigravity CLAUDE.md updated."
    fi
else
    cp -f "$CLAUDE_MD_SRC" "$CLAUDE_MD_DEST"
    echo "  -> Global CLAUDE.md deployed successfully."
fi

echo -n "[3/6] Enabling 1-Hour Prompt Caching (ENABLE_PROMPT_CACHING_1H=1)... "
export ENABLE_PROMPT_CACHING_1H=1
grep -q "ENABLE_PROMPT_CACHING_1H" "$HOME/.bashrc" 2>/dev/null || echo "export ENABLE_PROMPT_CACHING_1H=1" >> "$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && (grep -q "ENABLE_PROMPT_CACHING_1H" "$HOME/.zshrc" 2>/dev/null || echo "export ENABLE_PROMPT_CACHING_1H=1" >> "$HOME/.zshrc")
echo "[DONE]"

echo -n "[4/6] Registering global 'agy-settings' in PATH... "
cp -f "$SCRIPT_DIR/settings.sh" "$BIN_DIR/settings.sh"
cat << 'EOF' > "$BIN_DIR/agy-settings"
#!/usr/bin/env bash
bash "$HOME/.claude/bin/settings.sh"
EOF
chmod +x "$BIN_DIR/agy-settings" "$BIN_DIR/settings.sh"

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    export PATH="$BIN_DIR:$PATH"
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.zshrc"
fi
echo "[DONE]"

# 5. Register Compiler Language Server Plugins if claude is present
if command -v claude >/dev/null 2>&1; then
    echo "[5/6] Registering Compiler Language Servers (LSPs)..."
    for p in pyright-lsp@claude-plugins-official typescript-lsp@claude-plugins-official; do
        claude plugin install "$p" >/dev/null 2>&1 || true
    done
    echo "  -> Compiler LSPs installed (pyright, typescript - 0 token overhead, zero slash spam)."
fi

echo -n "[6/6] Copying Custom Instructions to Clipboard... "
if command -v pbcopy >/dev/null 2>&1; then
    cat "$SCRIPT_DIR/CLAUDE.md" | pbcopy
    echo "[COPIED (pbcopy)]"
elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard < "$SCRIPT_DIR/CLAUDE.md"
    echo "[COPIED (xclip)]"
elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$SCRIPT_DIR/CLAUDE.md"
    echo "[COPIED (wl-copy)]"
else
    echo "[MANUAL COPY REQUIRED]"
fi

echo ""
echo "=========================================================================="
echo "           1. CLAUDE DESKTOP CUSTOM INSTRUCTIONS (COPIED!)                "
echo "=========================================================================="
echo "+------------------------------------------------------------------------+"
echo "|  * ZERO CONVERSATIONAL FLUFF (Immediate engineering answers)           |"
echo "|  * MANDATORY ARTIFACTS (Plans, tasks, and walkthroughs in side panel)  |"
echo "|  * INTERACTIVE MERMAID DIAGRAMS (Rendered visually, not raw code)      |"
echo "|  * RIPPLE IMPACT DISCLOSURE (Blast radius check before code changes)   |"
echo "|  * HALT FOR APPROVAL GATE (Strict stop after planning)                 |"
echo "|  * TARGETED CHUNK DIFFS (Never dump entire files)                      |"
echo "+------------------------------------------------------------------------+"

echo ""
echo "=========================================================================="
echo "                      2. WHAT TO DO NEXT                                  "
echo "=========================================================================="
echo "  1. Open Claude Desktop (or Claude.ai web)."
echo "  2. Go to: Settings -> Custom Instructions."
echo "  3. Press Cmd + V (or Ctrl + V) to paste instructions."
echo "  4. Click Save."
echo "  5. Open your terminal, run 'claude', and start building!"

echo ""
echo "=========================================================================="
echo "                    3. SETTINGS & GLOBAL COMMAND                          "
echo "=========================================================================="
echo "  * All 12 skills and prompt caching are ENABLED by default."
echo "  * You can now run 'agy-settings' from ANY terminal!"
echo "  * Or run './settings.sh' anytime from this folder."
echo "=========================================================================="
echo ""
read -p "Run settings now? (y/N): " ans
if [[ "$ans" == [yY] ]]; then
    bash "$BIN_DIR/settings.sh"
fi
