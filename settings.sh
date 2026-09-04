#!/usr/bin/env bash
# Interactive Settings Manager for Antigravity-Claude Suite (macOS / Linux)

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
DISABLED_DIR="$CLAUDE_DIR/skills-disabled"
CATALOG_DIR="$CLAUDE_DIR/skills-catalog"
CONFIG_FILE="$CLAUDE_DIR/antigravity.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$SKILLS_DIR" "$DISABLED_DIR" "$CATALOG_DIR"

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

toggle_skill() {
    local skill="$1"
    if [ -d "$SKILLS_DIR/$skill" ]; then
        mv "$SKILLS_DIR/$skill" "$DISABLED_DIR/$skill"
        echo "Disabled $skill"
    elif [ -d "$DISABLED_DIR/$skill" ]; then
        mv "$DISABLED_DIR/$skill" "$SKILLS_DIR/$skill"
        echo "Enabled $skill"
    elif [ -d "$CATALOG_DIR/$skill" ]; then
        cp -r "$CATALOG_DIR/$skill" "$SKILLS_DIR/$skill"
        echo "Enabled $skill"
    fi
}

toggle_caching() {
    if [ "$ENABLE_PROMPT_CACHING_1H" = "1" ]; then
        export ENABLE_PROMPT_CACHING_1H=0
        sed -i '' '/ENABLE_PROMPT_CACHING_1H/d' "$HOME/.bashrc" 2>/dev/null || true
        sed -i '' '/ENABLE_PROMPT_CACHING_1H/d' "$HOME/.zshrc" 2>/dev/null || true
    else
        export ENABLE_PROMPT_CACHING_1H=1
        echo "export ENABLE_PROMPT_CACHING_1H=1" >> "$HOME/.bashrc"
        [ -f "$HOME/.zshrc" ] && echo "export ENABLE_PROMPT_CACHING_1H=1" >> "$HOME/.zshrc"
    fi
}

run_diagnostics() {
    clear
    echo "=========================================================================="
    echo "                 ANTIGRAVITY SYSTEM DIAGNOSTICS                           "
    echo "=========================================================================="
    if command -v claude >/dev/null 2>&1; then
        echo -e "  \033[32m[+]\033[0m Claude Code CLI:       Found ($(claude --version 2>&1 | head -n 1))"
    else
        echo -e "  \033[33m[!]\033[0m Claude Code CLI:       Not found in PATH"
    fi

    if [ "$ENABLE_PROMPT_CACHING_1H" = "1" ]; then
        echo -e "  \033[32m[+]\033[0m 1-Hour Prompt Caching: ACTIVE (ENABLE_PROMPT_CACHING_1H=1)"
    else
        echo -e "  \033[90m[!]\033[0m 1-Hour Prompt Caching: INACTIVE"
    fi

    if command -v rtk >/dev/null 2>&1; then
        echo -e "  \033[32m[+]\033[0m RTK Binary:            Installed ($(rtk --version 2>&1))"
    else
        echo -e "  \033[33m[!]\033[0m RTK Binary:            Not installed"
    fi

    if [ -f "$CLAUDE_DIR/settings.json" ] && grep -q "rtk hook claude" "$CLAUDE_DIR/settings.json"; then
        echo -e "  \033[32m[+]\033[0m Claude RTK Hook:       CONFIGURED in settings.json"
    else
        echo -e "  \033[33m[!]\033[0m Claude RTK Hook:       Not registered"
    fi

    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        echo -e "  \033[32m[+]\033[0m Global CLAUDE.md:      PRESENT (~/.claude/CLAUDE.md)"
    else
        echo -e "  \033[31m[!]\033[0m Global CLAUDE.md:      MISSING"
    fi

    echo "=========================================================================="
    read -p "Press Enter to return..." dummy
}

while true; do
    clear
    echo "=========================================================================="
    echo "                 ANTIGRAVITY CONFIGURATION & SETTINGS                     "
    echo "=========================================================================="
    echo "  Customize token-saving flags, companion proxies, and active skills.     "
    echo ""

    # Prompt Caching
    if [ "$ENABLE_PROMPT_CACHING_1H" = "1" ]; then
        echo -e "  [1] 1-Hour Prompt Caching           \033[32m[ ENABLED  ]\033[0m"
    else
        echo -e "  [1] 1-Hour Prompt Caching           \033[90m[ DISABLED ]\033[0m"
    fi

    # RTK
    if command -v rtk >/dev/null 2>&1; then
        echo -e "  [2] RTK (Rust Token Killer)          \033[32m[ INSTALLED ]\033[0m"
    else
        echo -e "  [2] RTK (Rust Token Killer)          \033[33m[ NOT INSTALLED ]\033[0m"
    fi

    echo " ------------------------------------------------------------------------"
    echo " BUNDLED SKILLS:"
    idx=3
    for s in "${ALL_SKILLS[@]}"; do
        if [ -d "$SKILLS_DIR/$s" ]; then
            printf "  [%2d] %-30s \033[32m[ ENABLED  ]\033[0m\n" "$idx" "$s"
        else
            printf "  [%2d] %-30s \033[90m[ DISABLED ]\033[0m\n" "$idx" "$s"
        fi
        ((idx++))
    done

    echo " ------------------------------------------------------------------------"
    echo "  [T] Run System Diagnostics"
    echo "  [C] Copy Custom Instructions to Clipboard"
    echo "  [U] Run Uninstaller"
    echo "  [0] Exit"
    echo "=========================================================================="
    read -p "Select option: " opt

    case "$opt" in
        1) toggle_caching ;;
        2) bash "$SCRIPT_DIR/scripts/install-rtk.sh" 2>/dev/null || true ;;
        3) toggle_skill "antigravity" ;;
        4) toggle_skill "antigravity-planner" ;;
        5) toggle_skill "frontend-design" ;;
        6) toggle_skill "test-driven-development" ;;
        7) toggle_skill "systematic-debugging" ;;
        8) toggle_skill "verification-before-completion" ;;
        9) toggle_skill "web-artifacts-builder" ;;
        10) toggle_skill "xlsx" ;;
        11) toggle_skill "pdf" ;;
        12) toggle_skill "docx" ;;
        t|T) run_diagnostics ;;
        c|C)
            cat "$SCRIPT_DIR/CLAUDE.md" | pbcopy 2>/dev/null || xclip -selection clipboard < "$SCRIPT_DIR/CLAUDE.md" 2>/dev/null || true
            echo "Copied to clipboard!"
            sleep 1
            ;;
        u|U)
            bash "$SCRIPT_DIR/uninstall.sh"
            exit 0
            ;;
        0) exit 0 ;;
        *) sleep 1 ;;
    esac
done
