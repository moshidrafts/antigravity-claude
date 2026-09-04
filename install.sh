#!/usr/bin/env bash
set -e

clear
echo "=========================================================================="
echo "               ANTIGRAVITY PROTOCOL SUITE FOR CLAUDE                      "
echo "=========================================================================="

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SKILLS="$SCRIPT_DIR/skills"

mkdir -p "$CLAUDE_DIR" "$SKILLS_DIR"

echo -n "[+] Deploying 10 skills to $SKILLS_DIR... "
if [ -d "$LOCAL_SKILLS" ]; then
    cp -r "$LOCAL_SKILLS"/* "$SKILLS_DIR/"
fi
echo "[DONE]"

echo -n "[+] Configuring global CLAUDE.md... "
if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    cp -f "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
fi
echo "[DONE]"

echo -n "[+] Enabling 1-Hour Prompt Caching (ENABLE_PROMPT_CACHING_1H=1)... "
export ENABLE_PROMPT_CACHING_1H=1
grep -q "ENABLE_PROMPT_CACHING_1H" "$HOME/.bashrc" 2>/dev/null || echo "export ENABLE_PROMPT_CACHING_1H=1" >> "$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && (grep -q "ENABLE_PROMPT_CACHING_1H" "$HOME/.zshrc" 2>/dev/null || echo "export ENABLE_PROMPT_CACHING_1H=1" >> "$HOME/.zshrc")
echo "[DONE]"

echo -n "[+] Copying Custom Instructions to Clipboard... "
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
echo "                    3. SETTINGS & CUSTOMIZATION                           "
echo "=========================================================================="
echo "  * All 10 skills and prompt caching are ENABLED by default."
echo "  * Want to toggle individual skills, disable caching, or install RTK?"
echo "  * Simply run './settings.sh' anytime from this folder!"
echo "=========================================================================="
echo ""
read -p "Run settings now? (y/N): " ans
if [[ "$ans" == [yY] ]]; then
    bash "$SCRIPT_DIR/settings.sh"
fi
