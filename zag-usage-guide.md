# Zag: Multi-Agent Worktree System - Usage Guide

## Overview

Zag launches 4 Claude Code agents in separate git worktrees within a Zellij 2x2 grid. Each agent works on an isolated branch, allowing parallel development without conflicts.

## Installation

```bash
# Ensure scripts are in ~/bin and executable
ls -la ~/bin/zag ~/bin/zag-reset ~/.zag-shell-init.sh

# Ensure ~/bin is in PATH
echo $PATH | grep "$HOME/bin"

# If not, add to shell config:
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc  # or ~/.bashrc
source ~/.zshrc
```

## Prerequisites

- Git 2.5+ (for worktree support)
- Zellij 0.40+ (for pane naming)
- Claude Code CLI (in PATH)
- Bash or Zsh

## Usage

### Launching Agents

From any git repository:

```bash
cd ~/Workspaces/my-project
zag
```

This will:
1. Create 4 git worktrees in sibling directories
2. Create timestamped branches for each (agent-N-YYYYMMDD-HHMM)
3. Launch Zellij with 2x2 grid
4. Start Claude in each pane
5. Customize prompts to show [Agent N]

### From Non-Git Directory

If you run `zag` from a non-git directory:
- **Option 1:** Initialize a new repo and proceed
- **Option 2:** Launch 4 vanilla Claude sessions (no worktrees)

### Resetting an Agent

When you finish work in an agent:

```bash
zag-reset
```

This will:
1. Check for uncommitted changes (blocks if found)
2. Check if branch is merged (warns if not)
3. Remove the worktree
4. Delete the branch
5. Offer 4 post-reset options:
   - **Create new worktree** - Start fresh with new branch
   - **Switch to existing worktree** - Move to another agent's workspace
   - **Return to main repo** - Go back to main repository
   - **Stay in current shell** - Remain in shell (directory deleted)

### Working in an Agent

Each agent pane has:
- **Isolated worktree directory** - Independent filesystem state
- **Independent branch** - No conflicts with other agents
- **[Agent N] prompt prefix** - Visual indicator of which agent
- **Environment variables:**
  - `ZAG_AGENT_NUM`: Agent number (1-4)
  - `ZAG_WORKTREE_PATH`: Full path to worktree

### Best Practices

1. **Commit frequently**: Each agent tracks its own branch
2. **Merge regularly**: Keep agents in sync with main branch
3. **Reset when done**: Clean up completed work promptly
4. **Use descriptive branches**: Override default names when creating new worktrees

### Workflow Example

```bash
# Launch agents
cd ~/project
zag

# In Agent 1: Work on feature A
[Agent 1] $ git checkout -b feature/auth
[Agent 1] $ # make changes
[Agent 1] $ git add -A && git commit -m "add auth"

# In Agent 2: Work on feature B in parallel
[Agent 2] $ git checkout -b feature/dashboard
[Agent 2] $ # make changes
[Agent 2] $ git add -A && git commit -m "add dashboard"

# Switch to terminal, merge Agent 1 work
$ cd ~/project
$ git merge --no-ff feature/auth

# Back in Agent 1: Reset and start new work
[Agent 1] $ zag-reset
# Choose option 1: Create new worktree
# Enter branch name: feature/api

# Agent 2 continues working independently
```

## Troubleshooting

### "claude command not found"
- Install Claude Code CLI: https://github.com/anthropics/claude-code
- Verify it's in PATH: `which claude`

### "zellij command not found"
- Install Zellij: https://zellij.dev/documentation/installation
- Verify version: `zellij --version` (need 0.40+)

### "No write permission to parent directory"
- Check permissions: `ls -ld $(dirname $PWD)`
- May need to use a different directory

### "Uncommitted changes" when resetting
- Commit your work: `git add -A && git commit -m "message"`
- Or stash it: `git stash`

### Prompt doesn't show [Agent N]
- Verify shell init sourced: `echo $ZAG_SHELL_INITIALIZED`
- Check env vars: `echo $ZAG_AGENT_NUM`
- May need to restart the pane

### Worktrees accumulating
- List: `git worktree list`
- Remove: `git worktree remove <path>`
- Or use `zag-reset` from within each worktree

## Advanced

### Manual Worktree Management

```bash
# List all worktrees
git worktree list

# Remove a worktree manually
git worktree remove /path/to/worktree

# Delete a branch
git branch -D branch-name

# Prune stale worktrees
git worktree prune
```

### Customizing Zag

Edit `~/bin/zag` to customize:
- **Grid layout** - Change KDL structure for different layouts
- **Number of agents** - Modify loop to create more/fewer agents
- **Branch naming pattern** - Change `generate_timestamp()` function
- **Shell command** - Replace "claude" with other tool

### Understanding Worktree Structure

For repo at `/Users/you/Workspaces/my-project`:

```
/Users/you/Workspaces/
├── my-project/                          # Main repo
├── my-project-wt-agent-1-20260312-1435/ # Agent 1 worktree
├── my-project-wt-agent-2-20260312-1435/ # Agent 2 worktree
├── my-project-wt-agent-3-20260312-1435/ # Agent 3 worktree
└── my-project-wt-agent-4-20260312-1435/ # Agent 4 worktree
```

Each worktree:
- Contains full copy of repository files
- Tracks independent branch
- Shares same .git database (efficient)
- Can be safely removed without affecting others

### Safety Features

**Uncommitted Changes Check:**
- zag-reset blocks if you have uncommitted changes
- Forces explicit commit or stash decision
- Prevents accidental data loss

**Merge Status Warning:**
- Warns if branch not merged to main
- Allows override with confirmation
- Helps track which work has been integrated

**Post-Reset Options:**
- Flexible workflow - choose what to do next
- No forced behavior - you control the next step
- Options for common scenarios (new work, switch context, return home)

## Common Scenarios

### Scenario: Quick Feature Development

```bash
# Launch and work on quick feature
cd ~/project && zag
[Agent 1] $ # implement feature
[Agent 1] $ git add -A && git commit -m "feat: add feature"

# Merge from outside Zellij
$ git merge --no-ff agent-1-*

# Reset and move on
[Agent 1] $ zag-reset  # Choose option 1 for new worktree
```

### Scenario: Long-Running Work Across Multiple Sessions

```bash
# Day 1: Start work
cd ~/project && zag
[Agent 1] $ # work on complex feature
[Agent 1] $ git commit -m "WIP: partial implementation"
[Agent 1] $ exit  # Or Ctrl+q to exit Zellij

# Day 2: Resume
cd ~/project && zag
# Zag creates new agents with new timestamps
# Your WIP branch still exists, switch to it manually:
[Agent 1] $ git checkout <your-wip-branch>
[Agent 1] $ # continue work
```

### Scenario: Parallel Development

```bash
cd ~/project && zag

# Agent 1: Frontend work
[Agent 1] $ git checkout -b feature/ui
[Agent 1] $ # work on UI

# Agent 2: Backend work
[Agent 2] $ git checkout -b feature/api
[Agent 2] $ # work on API

# Agent 3: Tests
[Agent 3] $ git checkout -b feature/tests
[Agent 3] $ # write tests

# Agent 4: Documentation
[Agent 4] $ git checkout -b feature/docs
[Agent 4] $ # update docs

# All agents work independently, merge when ready
```

### Scenario: Code Review and Testing

```bash
cd ~/project && zag

# Agent 1: Test a feature branch
[Agent 1] $ git fetch origin
[Agent 1] $ git checkout -b review/feature-x origin/feature-x
[Agent 1] $ # test the feature

# Agent 2: Review another PR
[Agent 2] $ git checkout -b review/pr-123 origin/pr-123
[Agent 2] $ # review changes

# Agents 3 & 4: Continue other work
```

## Understanding the Tools

### zag (Launcher)
- **Purpose:** Initialize multi-agent environment
- **When to use:** Start of work session
- **What it does:** Creates worktrees, launches Zellij
- **Location:** `~/bin/zag`

### zag-reset (Cleanup)
- **Purpose:** Clean up finished agent work
- **When to use:** When done with current worktree
- **What it does:** Safety checks, removal, menu
- **Location:** `~/bin/zag-reset`

### .zag-shell-init.sh (Prompt Customization)
- **Purpose:** Show [Agent N] in prompt
- **When used:** Automatically sourced by each pane
- **What it does:** Modifies PS1 for bash/zsh
- **Location:** `~/.zag-shell-init.sh`

## Tips and Tricks

1. **Use meaningful branch names** when creating new worktrees (option 1 in zag-reset menu)
2. **Merge frequently** to avoid divergence between agents
3. **One feature per agent** works better than context-switching within an agent
4. **Exit gracefully** with `Ctrl+q` in Zellij to avoid orphaned processes
5. **Clean up regularly** - use `git worktree list` to check for abandoned worktrees
6. **Reset completed agents** promptly to free up agent slots
7. **Use git stash** if you need to switch context mid-work
8. **Name your worktrees** - the custom branch name in option 1 helps identify work later

## Limitations

- **Fixed 4 agents** - Changing requires editing scripts
- **Same repository only** - Each zag session works with one repo
- **Zellij required** - No support for tmux/screen
- **Terminal-based** - Requires terminal multiplexer
- **Manual merging** - No automatic integration between agents

## Future Enhancements

See `docs/superpowers/specs/2026-03-12-zag-zellij-plugin-design.md` for ideas on a native Zellij plugin (Option B) that could provide:
- Custom keybindings
- Floating UI panels
- Session persistence
- Agent state monitoring
- Automated workflows

## References

- **Design Spec:** `docs/superpowers/specs/2026-03-12-zag-multi-agent-worktree-design.md`
- **Implementation Plan:** `docs/superpowers/plans/2026-03-12-zag-multi-agent-worktree.md`
- **Test Guide:** `docs/superpowers/testing/zag-manual-testing-guide.md`
- **Test Results:** `docs/superpowers/testing/zag-integration-test.md` (create after testing)
- **Fixes Applied:** `docs/superpowers/plans/2026-03-12-zag-FIXES-APPLIED.md`

## Version History

- **v1.0.0** (2026-03-12) - Initial release
  - 4-agent support
  - Git worktree isolation
  - Zellij 2x2 grid layout
  - Safety checks and cleanup
  - Post-reset menu
  - Shell prompt customization
  - Vanilla mode for non-git directories
