# Zag: Multi-Agent Worktree Setup for Zellij

**Date:** 2026-03-12
**Status:** Approved
**Approach:** Option A - Pure Shell + KDL Layout

## Overview

Zag (`zag`) is a command-line tool that launches a 2x2 grid of Claude Code agents in Zellij, each running in its own git worktree with independent branch isolation. It includes a reset mechanism (`zag-reset`) that safely cleans up individual worktrees when agents complete their work.

## Goals

- Launch 4 Claude Code agents simultaneously in a Zellij 2x2 grid
- Each agent operates in its own git worktree with a fresh timestamped branch
- Agents can be independently reset when work is complete
- Safety checks prevent data loss (uncommitted changes, unmerged branches)
- Simple, maintainable shell-based implementation

## User Experience

### Launch Flow

```bash
$ cd ~/Workspaces/golden-ami
$ zag
# Creates 4 worktrees, launches Zellij with 2x2 grid
# Each pane shows: [Agent N] user@host:~/Workspaces/golden-ami-wt-agent-N-20260312-1435$
# Claude starts automatically in each pane
```

**From non-git directory:**
```bash
$ cd ~/new-project
$ zag
Initialize git repository? [Y/n]: y
# Initializes repo, then launches as above
```

```bash
$ cd ~/new-project
$ zag
Initialize git repository? [Y/n]: n
# Launches 4 vanilla Claude terminals without worktrees
```

### Reset Flow

```bash
[Agent 2] $ zag-reset
Checking worktree status...
✓ No uncommitted changes
✓ Branch 'agent-2-20260312-1435' merged to main
Removing worktree...
✓ Worktree removed
✓ Branch deleted

What next?
1) Create new worktree in this pane
2) Switch to existing worktree
3) Return to main repo
4) Stay here
Choice [1-4]: 1

Enter branch name (or press Enter for timestamped): feature/add-auth
Creating new worktree...
✓ Created: ~/Workspaces/golden-ami-wt-agent-2-20260312-1502
[Agent 2] $
```

## Architecture

### Components

1. **`~/bin/zag`** - Main launcher script
2. **`~/bin/zag-reset`** - Worktree reset/cleanup script
3. **`~/.zag-shell-init.sh`** - Shell customization sourced by each pane

### Directory Structure

For repo at `/Users/dalekurt/Workspaces/golden-ami`:

```
/Users/dalekurt/Workspaces/
├── golden-ami/                          # Original repo
├── golden-ami-wt-agent-1-20260312-1435/ # Agent 1 worktree
├── golden-ami-wt-agent-2-20260312-1435/ # Agent 2 worktree
├── golden-ami-wt-agent-3-20260312-1435/ # Agent 3 worktree
└── golden-ami-wt-agent-4-20260312-1435/ # Agent 4 worktree
```

### Branch Naming

Pattern: `agent-N-YYYYMMDD-HHMM`

Examples:
- `agent-1-20260312-1435`
- `agent-2-20260312-1435`
- `agent-3-20260312-1435`
- `agent-4-20260312-1435`

All branches created from current HEAD at launch time.

## Implementation Details

### 1. `zag` Launcher Script

**Responsibilities:**
- Detect if current directory is a git repository
- If not, prompt to initialize or launch vanilla Claude sessions
- Extract repo name from directory path
- Generate timestamp for unique naming
- Create 4 git worktrees in sibling directories
- Generate Zellij KDL layout file dynamically
- Launch Zellij session with custom layout
- Clean up temporary layout file

**Key Operations:**

```bash
# Git repo detection
git rev-parse --git-dir >/dev/null 2>&1

# Shell detection with fallback
SHELL_CMD="${SHELL:-/bin/bash}"
case "$SHELL_CMD" in
  */zsh) SHELL_BIN="zsh" ;;
  */bash) SHELL_BIN="bash" ;;
  *) echo "Warning: Unsupported shell $SHELL_CMD, using bash"; SHELL_BIN="bash" ;;
esac

# Verify claude command exists
if ! command -v claude >/dev/null 2>&1; then
  echo "Error: claude command not found in PATH"
  exit 1
fi

# Worktree creation
TIMESTAMP=$(date +%Y%m%d-%H%M)
REPO_NAME=$(basename "$PWD")
for i in 1 2 3 4; do
  WORKTREE_PATH="../${REPO_NAME}-wt-agent-${i}-${TIMESTAMP}"
  BRANCH_NAME="agent-${i}-${TIMESTAMP}"
  git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" HEAD
done

# Setup trap for cleanup
LAYOUT_FILE="/tmp/zag-layout-$$.kdl"
trap "rm -f '$LAYOUT_FILE'" EXIT INT TERM

# Layout generation (dynamic KDL with complete pane configuration)
cat > "$LAYOUT_FILE" <<EOF
layout {
  pane split_direction="vertical" {
    pane split_direction="horizontal" {
      pane name="Agent 1" {
        command "$SHELL_BIN"
        args "-c" "export ZAG_AGENT_NUM=1 ZAG_WORKTREE_PATH=\"${PWD}/../${REPO_NAME}-wt-agent-1-${TIMESTAMP}\"; source ~/.zag-shell-init.sh; cd \"\$ZAG_WORKTREE_PATH\"; exec claude"
      }
      pane name="Agent 2" {
        command "$SHELL_BIN"
        args "-c" "export ZAG_AGENT_NUM=2 ZAG_WORKTREE_PATH=\"${PWD}/../${REPO_NAME}-wt-agent-2-${TIMESTAMP}\"; source ~/.zag-shell-init.sh; cd \"\$ZAG_WORKTREE_PATH\"; exec claude"
      }
    }
    pane split_direction="horizontal" {
      pane name="Agent 3" {
        command "$SHELL_BIN"
        args "-c" "export ZAG_AGENT_NUM=3 ZAG_WORKTREE_PATH=\"${PWD}/../${REPO_NAME}-wt-agent-3-${TIMESTAMP}\"; source ~/.zag-shell-init.sh; cd \"\$ZAG_WORKTREE_PATH\"; exec claude"
      }
      pane name="Agent 4" {
        command "$SHELL_BIN"
        args "-c" "export ZAG_AGENT_NUM=4 ZAG_WORKTREE_PATH=\"${PWD}/../${REPO_NAME}-wt-agent-4-${TIMESTAMP}\"; source ~/.zag-shell-init.sh; cd \"\$ZAG_WORKTREE_PATH\"; exec claude"
      }
    }
  }
}
EOF

# Launch Zellij
zellij --layout "$LAYOUT_FILE" --session "zag-${REPO_NAME}"
# Cleanup happens automatically via trap
```

### 2. `zag-reset` Script

**Responsibilities:**
- Identify current worktree from `$PWD`
- Verify no uncommitted changes (`git status --porcelain`)
- Check if branch merged to main/master
- Prompt for confirmation if unmerged
- Remove worktree via `git worktree remove`
- Delete branch via `git branch -D`
- Present post-reset menu with 4 options
- Execute user's choice

**Worktree Identification:**
```bash
# Normalize current path
CURRENT_PATH=$(cd "$PWD" && pwd -P)

# Verify this is actually a git worktree
if ! git worktree list --porcelain | grep -q "worktree $CURRENT_PATH"; then
  echo "Error: Not in a git worktree"
  exit 1
fi

# Verify this is a zag-created worktree by checking naming pattern
if [[ "$CURRENT_PATH" =~ -wt-agent-([0-9]+)- ]]; then
  AGENT_NUM="${BASH_REMATCH[1]}"
else
  echo "Error: Not in a zag worktree (naming pattern mismatch)"
  echo "Zag worktrees follow pattern: repo-name-wt-agent-N-timestamp"
  exit 1
fi

# Extract current branch name
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
```

**Safety Checks:**

```bash
# Uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Uncommitted changes. Commit or stash first."
  exit 1
fi

# Merge status - try multiple methods to find default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

# Fallback to common branch names if origin/HEAD not set
if [ -z "$DEFAULT_BRANCH" ]; then
  for branch in main master; do
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      DEFAULT_BRANCH="$branch"
      break
    fi
  done
fi

# Final fallback to current HEAD
if [ -z "$DEFAULT_BRANCH" ]; then
  DEFAULT_BRANCH=$(git symbolic-ref --short HEAD)
fi

if ! git branch --merged "$DEFAULT_BRANCH" | grep -q "$CURRENT_BRANCH"; then
  read -p "Branch not merged to $DEFAULT_BRANCH. Proceed anyway? [y/N]: " confirm
  [[ "$confirm" != "y" ]] && exit 1
fi
```

**Post-Reset Menu:**

```
What next?
1) Create new worktree in this pane
2) Switch to existing worktree
3) Return to main repo
4) Stay here
```

**Option 1 - Create new worktree:**
```bash
# Prompt for branch name
read -p "Enter branch name (or press Enter for timestamped): " CUSTOM_NAME
if [ -z "$CUSTOM_NAME" ]; then
  NEW_TIMESTAMP=$(date +%Y%m%d-%H%M)
  NEW_BRANCH="agent-${ZAG_AGENT_NUM}-${NEW_TIMESTAMP}"
else
  NEW_BRANCH="$CUSTOM_NAME"
fi

# Create worktree
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
NEW_WORKTREE="../${REPO_NAME}-wt-agent-${ZAG_AGENT_NUM}-$(date +%Y%m%d-%H%M)"
git worktree add -b "$NEW_BRANCH" "$NEW_WORKTREE" HEAD

# Switch to it and restart Claude
export ZAG_WORKTREE_PATH="$NEW_WORKTREE"
cd "$NEW_WORKTREE"
exec claude  # Replace current shell process
```

**Option 2 - Switch to existing:**
```bash
# List available worktrees
git worktree list
read -p "Enter worktree path: " SELECTED_PATH

# Validate and switch
if git worktree list --porcelain | grep -q "worktree $SELECTED_PATH"; then
  export ZAG_WORKTREE_PATH="$SELECTED_PATH"
  cd "$SELECTED_PATH"
  exec claude
else
  echo "Invalid worktree path"
  exit 1
fi
```

**Option 3 - Return to main:**
```bash
# Get main repo root
REPO_ROOT=$(git rev-parse --show-toplevel)
unset ZAG_WORKTREE_PATH
cd "$REPO_ROOT"
exec claude
```

**Option 4 - Stay here:**
```bash
# Do nothing - shell remains active in deleted directory
# User can manually cd elsewhere or exit
echo "Staying in current shell. Note: directory has been deleted."
```

### 3. Shell Customization (`~/.zag-shell-init.sh`)

**Responsibilities:**
- Modify PS1 to prepend `[Agent N]` prefix
- Preserve user's existing prompt styling
- Detect shell type (bash vs zsh)
- Export helper variables

**Implementation:**

```bash
#!/bin/bash
# Sourced by each pane on startup

# Prevent double-sourcing
if [ -n "$ZAG_SHELL_INITIALIZED" ]; then
  return 0
fi
export ZAG_SHELL_INITIALIZED=1

# Detect shell and modify prompt appropriately
if [ -n "$ZSH_VERSION" ]; then
  # Zsh - use precmd hook to avoid double prefixes
  precmd_functions+=(zag_prompt)
  zag_prompt() {
    # Only add prefix if not already present
    if [[ "$PS1" != *"[Agent ${ZAG_AGENT_NUM}]"* ]]; then
      PS1="[Agent ${ZAG_AGENT_NUM}] ${PS1}"
    fi
  }
elif [ -n "$BASH_VERSION" ]; then
  # Bash - use PROMPT_COMMAND to avoid double prefixes
  _zag_prompt_command() {
    # Strip existing prefix and add fresh one
    PS1="${PS1#\[Agent ${ZAG_AGENT_NUM}\] }"
    PS1="[Agent ${ZAG_AGENT_NUM}] ${PS1}"
  }
  PROMPT_COMMAND="_zag_prompt_command${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi

export PS1
export ZAG_WORKTREE_PATH  # Already set by pane command
export ZAG_AGENT_NUM       # Already set by pane command
```

## Data Flow

### Launch Sequence

1. User runs `zag` from `/Users/dalekurt/Workspaces/golden-ami`
2. Script validates: `git rev-parse --git-dir` succeeds
3. Extract repo name: `golden-ami`
4. Generate timestamp: `20260312-1435`
5. Create worktrees (loop 1-4):
   - Path: `/Users/dalekurt/Workspaces/golden-ami-wt-agent-N-20260312-1435`
   - Branch: `agent-N-20260312-1435` from HEAD
6. Generate KDL layout in `/tmp/zag-layout-<PID>.kdl`
7. Setup trap to cleanup layout file on exit: `trap "rm -f '$LAYOUT_FILE'" EXIT INT TERM`
8. Launch: `zellij --layout /tmp/zag-layout-<PID>.kdl --session zag-golden-ami`
9. Each pane executes:
   - Export `ZAG_AGENT_NUM` and `ZAG_WORKTREE_PATH`
   - Source `~/.zag-shell-init.sh`
   - `cd` to worktree
   - Launch `claude`
10. Cleanup temp layout file happens automatically via trap when script exits

### Reset Sequence

1. Agent in worktree runs `zag-reset`
2. Parse current worktree from `$PWD` or `ZAG_WORKTREE_PATH`
3. Extract branch name: `agent-2-20260312-1435`
4. Check uncommitted: `git status --porcelain` (abort if not empty)
5. Check merged: `git branch --merged main` (warn if not found)
6. Remove worktree: `git worktree remove $WORKTREE_PATH`
7. Delete branch: `git branch -D $BRANCH_NAME`
8. Display menu, read user input (1-4)
9. Execute selected action

## Error Handling

### Launch Errors

| Error | Detection | Response |
|-------|-----------|----------|
| Not a git repo | `git rev-parse` fails | Prompt to initialize or launch vanilla |
| Worktree creation fails | `git worktree add` non-zero exit | Show error, suggest checking git version/permissions |
| Zellij not installed | `which zellij` fails | Show install instructions |
| Permission denied (parent dir) | `mkdir` or `git worktree` EACCES | Error message with permission guidance |
| Zellij launch fails | `zellij` non-zero exit | Show error output, suggest checking config |

### Reset Errors

| Error | Detection | Response |
|-------|-----------|----------|
| Uncommitted changes | `git status --porcelain` output | Abort with message to commit/stash |
| Branch not merged | Not in `git branch --merged` | Warn, require explicit confirmation |
| Not in worktree | `$PWD` not matching worktree pattern | Error: "Not in a zag worktree" |
| Worktree already removed | `git worktree list` doesn't show path | Skip worktree removal, continue to branch deletion |
| Branch protected | `git branch -D` fails | Show error, suggest manual cleanup |

All errors use safe defaults: never force-delete uncommitted work, always confirm destructive actions.

## Testing Strategy

### Manual Test Scenarios

**1. Happy Path - From Git Repo**
- Launch `zag` from existing repo
- Verify: 4 worktrees created with correct naming pattern
- Verify: Zellij launches with 2x2 grid
- Verify: Pane names show "Agent 1" through "Agent 4"
- Verify: Prompts show `[Agent N]` prefix
- Verify: `claude` command starts in each pane
- Verify: Each pane in different worktree directory

**2. Non-Git Directory - Initialize**
- Run `zag` from non-git directory
- Select "Yes" to initialize
- Verify: Git repo initialized
- Verify: Launches normally as test #1

**3. Non-Git Directory - Skip**
- Run `zag` from non-git directory
- Select "No" to initialization
- Verify: 4 vanilla Claude sessions launch (no worktrees)
- Verify: All in same directory

**4. Reset - Clean State**
- Agent completes work, commits, merges to main
- Run `zag-reset`
- Verify: No warnings about uncommitted/unmerged
- Verify: Worktree directory removed from filesystem
- Verify: Branch deleted from repo
- Test each menu option (1-4) works correctly

**5. Reset - Uncommitted Changes**
- Make changes without committing
- Run `zag-reset`
- Verify: Aborts with error message
- Verify: Worktree and branch still exist

**6. Reset - Unmerged Branch**
- Commit work but don't merge
- Run `zag-reset`
- Verify: Warns about unmerged branch
- Enter "N" - verify abort, work preserved
- Run again, enter "Y" - verify proceeds with cleanup

**7. Reset - Not In Worktree**
- `cd` to main repo
- Run `zag-reset`
- Verify: Error message "Not in a zag worktree"

**8. Edge Cases**
- Repo with no remote configured
- Detached HEAD state when launching
- Multiple `zag` sessions running simultaneously
- Killing Zellij vs clean exit
- Shell type: test in both bash and zsh

### Validation Points

✓ Worktrees created as siblings to repo, not nested
✓ Branch names follow `agent-N-YYYYMMDD-HHMM` format
✓ No orphaned worktrees after reset
✓ No orphaned branches after confirmed reset
✓ Shell prompt correctly shows agent number
✓ `zag-reset` command available in PATH
✓ Temp layout file cleaned up
✓ Works in bash and zsh
✓ Claude inherits customized environment

## Installation

```bash
# 1. Copy scripts to user bin
cp zag ~/bin/
cp zag-reset ~/bin/
cp zag-shell-init.sh ~/.zag-shell-init.sh
chmod +x ~/bin/zag ~/bin/zag-reset

# 2. Ensure ~/bin in PATH (add to ~/.zshrc or ~/.bashrc if needed)
export PATH="$HOME/bin:$PATH"

# 3. Verify Zellij installed
zellij --version  # Should be 0.40.0+
```

## Future Enhancements (Out of Scope)

- Configurable grid size (3x3, 1x4, etc.)
- Different Claude models per pane
- Shared tmux/screen compatibility mode
- Integration with project management tools
- Auto-merge small agents back to main
- Worktree templates/scaffolding

## Related: Option B Spec (Side Project)

See: `2026-03-12-zag-zellij-plugin-design.md` for the Zellij plugin (Rust/WASM) approach as a future enhancement project.
