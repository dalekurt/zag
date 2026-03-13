#!/bin/bash
# Zag Shell Initialization
# Sourced by each Zellij pane to customize the prompt

# Prevent double-sourcing
if [ -n "$ZAG_SHELL_INITIALIZED" ]; then
    return 0
fi
export ZAG_SHELL_INITIALIZED=1

# Detect shell and modify prompt appropriately
if [ -n "$ZSH_VERSION" ]; then
    # Zsh - use precmd hook to avoid double prefixes
    zag_prompt() {
        # Only add prefix if not already present
        if [[ "$PS1" != *"[Agent ${ZAG_AGENT_NUM}]"* ]]; then
            PS1="[Agent ${ZAG_AGENT_NUM}] ${PS1}"
        fi
    }
    # Only add function if not already in precmd_functions
    if [[ " ${precmd_functions[@]} " != *" zag_prompt "* ]]; then
        precmd_functions+=(zag_prompt)
    fi

elif [ -n "$BASH_VERSION" ]; then
    # Bash - use PROMPT_COMMAND to avoid double prefixes
    _zag_prompt_command() {
        # Strip existing prefix and add fresh one
        PS1="${PS1#\[Agent ${ZAG_AGENT_NUM}\] }"
        PS1="[Agent ${ZAG_AGENT_NUM}] ${PS1}"
    }
    # Only add to PROMPT_COMMAND if not already present
    if [[ "$PROMPT_COMMAND" != *"_zag_prompt_command"* ]]; then
        PROMPT_COMMAND="_zag_prompt_command${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    fi
fi

# Ensure environment variables are exported
export PS1
export ZAG_WORKTREE_PATH
export ZAG_AGENT_NUM
