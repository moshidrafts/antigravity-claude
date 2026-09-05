#!/usr/bin/env bash
# Interactive Settings Manager for Antigravity-Claude Suite (macOS / Linux)

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
DISABLED_DIR="$CLAUDE_DIR/skills-disabled"
CATALOG_DIR="$CLAUDE_DIR/skills-catalog"
CONFIG_FILE="$CLAUDE_DIR/antigravity.json"
BIN_DIR="$CLAUDE_DIR/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$SKILLS_DIR" "$DISABLED_DIR" "$CATALOG_DIR" "$BIN_DIR"

ALL_SKILLS=(
    "antigravity"
    "antigravity-planner"
    "caveman"
    "frontend-design"
    "test-driven-development"
    "systematic-debugging"
    "verification-before-completion"
    "web-artifacts-builder"
    "xlsx"
    "pdf"
    "docx"
)

declare -A SKILL_DESC
SKILL_DESC["antigravity"]="Core zero-fluff protocol & targeted chunk-diff rules"
SKILL_DESC["antigravity-planner"]="Mandatory Mermaid architecture flowcharts & approval gates"
SKILL_DESC["caveman"]="JuliusBrussee: Ultra-compressed token communication (cuts 60-75% output tokens)"
SKILL_DESC["frontend-design"]="Anthropic boutique visual design standards (anti-AI slop)"
SKILL_DESC["test-driven-development"]="obra/superpowers: Enforces failing tests before writing code"
SKILL_DESC["systematic-debugging"]="obra/superpowers: 4-phase root cause analysis before fixes"
SKILL_DESC["verification-before-completion"]="obra/superpowers: Requires automated test proof before claims"
SKILL_DESC["web-artifacts-builder"]="Anthropic: React 18 + Tailwind + shadcn/ui multi-component apps"
SKILL_DESC["xlsx"]="Anthropic: Native Excel spreadsheet creation, formulas & data"
SKILL_DESC["pdf"]="Anthropic: PDF text/table extraction, page merging & OCR"
SKILL_DESC["docx"]="Anthropic: Word document formatting, styling & template generator"

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

remove_line_from_file() {
    local pattern="$1"
    local file="$2"
    [ -f "$file" ] || return 0
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$pattern" "$file" 2>/dev/null || true
    else
        sed -i "$pattern" "$file" 2>/dev/null || true
    fi
}

toggle_caching() {
    if [ "$ENABLE_PROMPT_CACHING_1H" = "1" ]; then
        export ENABLE_PROMPT_CACHING_1H=0
        remove_line_from_file '/ENABLE_PROMPT_CACHING_1H/d' "$HOME/.bashrc"
        remove_line_from_file '/ENABLE_PROMPT_CACHING_1H/d' "$HOME/.zshrc"
    else
        export ENABLE_PROMPT_CACHING_1H=1
        echo "export ENABLE_PROMPT_CACHING_1H=1" >> "$HOME/.bashrc"
        [ -f "$HOME/.zshrc" ] && echo "export ENABLE_PROMPT_CACHING_1H=1" >> "$HOME/.zshrc"
    fi
}

show_guide() {
    clear
    echo "=========================================================================="
    echo "               IN-DEPTH FEATURE & SETTINGS GUIDE                          "
    echo "=========================================================================="
    cat << 'EOF'
TOKEN OPTIMIZATIONS & COMPANIONS:
--------------------------------------------------------------------------
1. 1-Hour Prompt Caching (ENABLE_PROMPT_CACHING_1H=1)
   - Caches system prompts and repo context in server RAM for 1 hour.
   - Saves up to 90% on input tokens during back-and-forth debugging sessions.

2. RTK (Rust Token Killer)
   - High-speed Rust proxy that strips boilerplate, noisy logs, and progress bars
     from git, test, and package manager commands before reaching Claude.
   - Reduces bash output tokens by 60% to 90%.

3. Graphify AST Codebase Graph
   - Pre-maps your codebase AST relationships so Claude navigates symbols
     directly instead of grepping files.

BUNDLED SKILLS:
--------------------------------------------------------------------------
4. antigravity: Core chunked editing & zero-fluff engineering protocol.
5. antigravity-planner: Mandatory Mermaid diagrams & human approval gates.
6. caveman: JuliusBrussee ultra-compressed token communication (cuts 60-75% output tokens).
7. frontend-design: Anthropic boutique visual design standards (anti-AI slop).
8. test-driven-development: obra/superpowers: Failing tests before code.
9. systematic-debugging: 4-phase root cause analysis before making fixes.
10. verification-before-completion: Requires automated test proof before claims.
11. web-artifacts-builder: React 18 + Tailwind + shadcn/ui multi-component apps.
12. xlsx: Excel spreadsheet creation, formulas, and data cleaning.
13. pdf: PDF table extraction, page merging, and OCR.
14. docx: Word document formatting, styling, and templates.
==========================================================================
EOF
    read -r -p "Press Enter to return..." dummy || return 0
}

run_diagnostics() {
    clear
    echo "=========================================================================="
    echo "                 ANTIGRAVITY SYSTEM DIAGNOSTICS                           "
    echo "=========================================================================="
    if command -v claude >/dev/null 2>&1; then
        cVer=$(claude --version 2>&1 | head -n 1)
        echo -e "  \033[32m[+]\033[0m Claude Code CLI:       Found ($cVer)"
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

    if command -v graphify >/dev/null 2>&1; then
        echo -e "  \033[32m[+]\033[0m Graphify AST CLI:      Installed ($(graphify --version 2>&1 || echo 'present'))"
    else
        echo -e "  \033[90m[!]\033[0m Graphify AST CLI:      Not installed (pip install graphifyy)"
    fi

    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        echo -e "  \033[32m[+]\033[0m Global CLAUDE.md:      PRESENT (~/.claude/CLAUDE.md)"
    else
        echo -e "  \033[31m[!]\033[0m Global CLAUDE.md:      MISSING"
    fi

    activeCount=0
    for s in "${ALL_SKILLS[@]}"; do
        [ -d "$SKILLS_DIR/$s" ] && ((activeCount++))
    done
    echo -e "  \033[32m[+]\033[0m Active Skills:         $activeCount/${#ALL_SKILLS[@]} enabled"

    if command -v claude >/dev/null 2>&1; then
        mCount=$(claude plugin marketplace list 2>&1 | grep -c "^  >" || true)
        echo -e "  \033[32m[+]\033[0m Claude Marketplaces:   $mCount configured (centminmod, official, community)"
        pCount=$(claude plugin list 2>&1 | grep -c "^  >" || true)
        echo -e "  \033[32m[+]\033[0m Claude Code Plugins:   $pCount installed (session-metrics, LSPs, dev-suite)"
    fi

    if command -v agy-settings >/dev/null 2>&1 || [ -f "$BIN_DIR/agy-settings" ]; then
        echo -e "  \033[32m[+]\033[0m Global agy-settings:   AVAILABLE ('agy-settings' in any terminal)"
    else
        echo -e "  \033[33m[!]\033[0m Global agy-settings:   Not linked"
    fi

    echo "=========================================================================="
    read -r -p "Press Enter to return..." dummy || return 0
}

while true; do
    clear
    echo "=========================================================================="
    echo "                 ANTIGRAVITY CONFIGURATION & SETTINGS                     "
    echo "=========================================================================="
    echo "  Toggle token optimizations, CLI proxies, and active skills anytime.     "
    echo ""

    if [ "$ENABLE_PROMPT_CACHING_1H" = "1" ]; then
        echo -e "  [1] 1-Hour Prompt Caching           \033[32m[ ENABLED  ]\033[0m"
    else
        echo -e "  [1] 1-Hour Prompt Caching           \033[90m[ DISABLED ]\033[0m"
    fi
    echo -e "      \033[90m|-- Caches prompts & workspace in RAM for 1h (cuts 90% prompt cost)\033[0m"

    if command -v rtk >/dev/null 2>&1; then
        echo -e "  [2] RTK (Rust Token Killer)          \033[32m[ INSTALLED ]\033[0m"
    else
        echo -e "  [2] RTK (Rust Token Killer)          \033[33m[ NOT INSTALLED ]\033[0m"
    fi
    echo -e "      \033[90m|-- Strips CLI boilerplate/progress bars from git/npm/tests (60-90% savings)\033[0m"

    echo -e "  [3] Graphify AST Codebase Graph     \033[90m[ OPTIONAL ]\033[0m"
    echo -e "      \033[90m|-- Pre-maps codebase symbol relationships so Claude doesn't burn tokens grepping\033[0m"

    echo " ------------------------------------------------------------------------"
    echo " BUNDLED SKILLS:"
    idx=4
    for s in "${ALL_SKILLS[@]}"; do
        if [ -d "$SKILLS_DIR/$s" ]; then
            printf "  [%2d] %-30s \033[32m[ ENABLED  ]\033[0m\n" "$idx" "$s"
        else
            printf "  [%2d] %-30s \033[90m[ DISABLED ]\033[0m\n" "$idx" "$s"
        fi
        desc="${SKILL_DESC[$s]}"
        if [ -n "$desc" ]; then
            printf "      \033[90m|-- %s\033[0m\n" "$desc"
        fi
        ((idx++))
    done

    echo " ------------------------------------------------------------------------"
    echo "  [?] View In-Depth Feature Guide"
    echo "  [T] Run System Diagnostics"
    echo "  [C] Copy Custom Instructions to Clipboard"
    echo "  [U] Run Uninstaller"
    echo "  [0] Exit"
    echo "=========================================================================="
    if ! read -r -p "Select option (0-14, ?, T, C, U): " opt; then
        exit 0
    fi

    case "$opt" in
        1) toggle_caching ;;
        2) bash "$SCRIPT_DIR/scripts/install-rtk.sh" 2>/dev/null || true ;;
        3)
            if command -v graphify >/dev/null 2>&1; then
                toggle_skill "graphify"
            else
                echo "Graphify CLI not detected. To install: pip install graphifyy"
                read -p "Install graphifyy now via pip? (y/N): " gAns
                if [[ "$gAns" =~ ^[Yy]$ ]]; then
                    pip install graphifyy && toggle_skill "graphify"
                fi
            fi
            ;;
        4) toggle_skill "antigravity" ;;
        5) toggle_skill "antigravity-planner" ;;
        6) toggle_skill "caveman" ;;
        7) toggle_skill "frontend-design" ;;
        8) toggle_skill "test-driven-development" ;;
        9) toggle_skill "systematic-debugging" ;;
        10) toggle_skill "verification-before-completion" ;;
        11) toggle_skill "web-artifacts-builder" ;;
        12) toggle_skill "xlsx" ;;
        13) toggle_skill "pdf" ;;
        14) toggle_skill "docx" ;;
        \?) show_guide ;;
        t|T) run_diagnostics ;;
        c|C)
            cat "$SCRIPT_DIR/CLAUDE.md" | pbcopy 2>/dev/null || xclip -selection clipboard < "$SCRIPT_DIR/CLAUDE.md" 2>/dev/null || wl-copy < "$SCRIPT_DIR/CLAUDE.md" 2>/dev/null || true
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
