# Contributing to Antigravity Protocol for Claude

Thank you for your interest in improving the **Antigravity Protocol for Claude**! 🚀

## Core Principles
1. **Zero Fluff**: Every skill and instruction must prioritize concise, high-signal engineering output.
2. **Token Efficiency**: Respect context windows. Enforce chunk-based edits and prompt caching.
3. **Visual Architecture**: Mandate visual diagrams (Mermaid / SVG) for complex multi-step tasks.
4. **Approval Gates**: Always halt after planning to keep human developers in full control.

---

## Adding a New Skill
1. Create a subdirectory under `skills/<skill-name>/`.
2. Add a `SKILL.md` containing standardized YAML frontmatter:
   ```yaml
   ---
   name: <skill-name>
   description: <Clear explanation of when Claude Code should trigger this skill>
   author: <Your Name / Organization>
   version: 1.0.0
   ---
   ```
3. Test the skill locally with Claude Code:
   ```bash
   cp -r skills/<skill-name> ~/.claude/skills/
   claude
   ```
4. Update `settings.bat` and `settings.sh` if registering as an interactive toggle.
5. Submit a Pull Request!
