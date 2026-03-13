# Zag - Multi-Agent Worktree System

Launch 4 Claude Code agents in isolated git worktrees within a Zellij 2x2 grid for parallel development.

## Features

- **Isolated Git Worktrees** - Each agent works on its own timestamped branch
- **Zellij 2x2 Grid** - Automatic terminal multiplexer layout
- **Safety Checks** - Uncommitted changes detection, merge status verification
- **Smart Reset** - Post-reset menu with 4 options (create new, switch, return, stay)
- **Non-Git Support** - Vanilla mode for non-git directories
- **Shell Customization** - [Agent N] prompt prefix (bash/zsh)

## Installation

```bash
./install.sh
```

Ensure `~/bin` is in your PATH:
```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc  # or ~/.bashrc
source ~/.zshrc
```

## Requirements

- **Git** 2.5+ (worktree support)
- **Zellij** 0.40+ ([install](https://zellij.dev/documentation/installation))
- **Claude Code CLI** ([install](https://github.com/anthropics/claude-code))
- **Shell**: bash or zsh

## Quick Start

```bash
# Launch from any git repository
cd your-project
zag

# Four agents appear in 2x2 grid
# Each works on isolated branch: agent-N-YYYYMMDD-HHMM

# When done with an agent
zag-reset
# Choose: create new worktree, switch to existing, return to main, or stay
```

## Commands

### `zag`
Main launcher - creates worktrees and launches Zellij session

**From git repo:**
- Creates 4 worktrees in sibling directories
- Launches Zellij with 2x2 grid
- Starts Claude in each pane with custom prompt

**From non-git directory:**
- Prompts to initialize git
- Or launches 4 vanilla Claude sessions

### `zag-reset`
Cleanup script - safely removes worktree and branch

**Safety checks:**
- Blocks if uncommitted changes
- Warns if branch not merged
- Validates zag-created worktree

**Post-reset menu:**
1. Create new worktree with custom branch name
2. Switch to existing worktree
3. Return to main repository
4. Stay in current shell

## Use Cases

**Parallel Development**
- Agent 1: Frontend
- Agent 2: Backend
- Agent 3: Tests
- Agent 4: Documentation

**Code Review**
- Test multiple PRs simultaneously

**Rapid Prototyping**
- Explore different approaches in parallel

## Workflow Example

```bash
# Launch agents
cd ~/project
zag

# In Agent 1: Work on feature A
[Agent 1] $ git checkout -b feature/auth
[Agent 1] $ # make changes
[Agent 1] $ git commit -m "add auth"

# In Agent 2: Work on feature B (parallel)
[Agent 2] $ git checkout -b feature/dashboard
[Agent 2] $ # make changes
[Agent 2] $ git commit -m "add dashboard"

# Outside Zellij: Merge Agent 1 work
$ cd ~/project
$ git merge --no-ff feature/auth

# Back in Agent 1: Reset and start new work
[Agent 1] $ zag-reset
# Choose option 1: Create new worktree
# Enter branch name: feature/api
```

## Technical Details

**Worktree Structure:**
```
/path/to/project/
├── project/                          # Main repo
├── project-wt-agent-1-YYYYMMDD-HHMM/ # Agent 1 worktree
├── project-wt-agent-2-YYYYMMDD-HHMM/ # Agent 2 worktree
├── project-wt-agent-3-YYYYMMDD-HHMM/ # Agent 3 worktree
└── project-wt-agent-4-YYYYMMDD-HHMM/ # Agent 4 worktree
```

**Environment Variables (per agent):**
- `ZAG_AGENT_NUM` - Agent number (1-4)
- `ZAG_WORKTREE_PATH` - Full path to worktree

**Performance:**
- Worktree creation: ~1-2 seconds for 4 worktrees
- Zellij launch: Near-instant
- Reset operation: <1 second

## Files

- `zag` - Main launcher (10KB)
- `zag-reset` - Cleanup script (8.5KB)
- `.zag-shell-init.sh` - Prompt customization (1.3KB)

## Documentation

- [Usage Guide](zag-usage-guide.md) - Comprehensive usage documentation
- [Design Spec](DESIGN.md) - Complete design specification

## Version

**v1.0.0** - Initial release (2026-03-12)

## License

MIT

## Contributing

Issues and pull requests welcome at [github.com/dalekurt/zag](https://github.com/dalekurt/zag)
