#!/bin/bash
#
# Byron Peebles, based on https://gist.github.com/insin/1425703
# Changes from that are:
#  * single line prompt
#  * speed up git repo detection
#  * rejigger some of the verbage and how it decides about git up/down status.
#
# DESCRIPTION:
#
# Set the bash prompt according to:
# * the active virtualenv
# * the branch/status of the current git repository
# * the return value of the previous command
#
# USAGE:
#
# 1. Save this file as ~/.bash_prompt
# 2. Add the following line to the end of your ~/.bashrc or ~/.bash_profile:
# . ~/.bash_prompt
#
# LINEAGE:
#
# Based on work by woods
#
# https://gist.github.com/31967

# The various escape codes that we can use to color our prompt.
RED="\[\033[0;31m\]"
YELLOW="\[\033[1;33m\]"
GREEN="\[\033[0;32m\]"
BLUE="\[\033[1;34m\]"
LIGHT_RED="\[\033[1;31m\]"
LIGHT_GREEN="\[\033[1;32m\]"
WHITE="\[\033[1;37m\]"
LIGHT_GRAY="\[\033[0;37m\]"
COLOR_NONE="\[\e[0m\]"

# Detect whether the current directory is a git repository.
is_git_repository () {
    [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1
}

# Determine the branch/state information for this git repository.
set_git_branch () {
    # Capture the output of the "git status" command.
    git_status="$(git status 2> /dev/null)"

    # Set color based on clean/staged/dirty.
    if [[ ${git_status} =~ "working directory clean" ]]; then
        state="${GREEN}"
    elif [[ ${git_status} =~ "Changes to be committed" ]]; then
        state="${YELLOW}"
    else
        state="${LIGHT_RED}"
    fi

    # Set arrow icon based on status against remote.
    remote_pattern="(# |)Your branch is (\w*) (of|by|)"
    if [[ ${git_status} =~ ${remote_pattern} ]]; then
        if [[ ${BASH_REMATCH[2]} == "ahead" ]]; then
            remote="↑"
        else
            remote="↓"
        fi
    else
        diverge_pattern="(# |)Your branch and (.*) have diverged"
        if [[ ${git_status} =~ ${diverge_pattern} ]]; then
            remote="↕"
        else
            remote=""
        fi
    fi

    # Get the name of the branch.
    branch_pattern="(# |)On branch ([^${IFS}]*)"
    if [[ ${git_status} =~ ${branch_pattern} ]]; then
        branch=${BASH_REMATCH[2]}
    fi

    # Set the final branch string.
    BRANCH="${state}(${branch})${remote}${COLOR_NONE}"
}

# Return the prompt symbol to use, colorized based on the return value of the
# previous command.
set_prompt_symbol () {
    if test $1 -eq 0 ; then
        PROMPT_SYMBOL="\$"
    else
        PROMPT_SYMBOL="${LIGHT_RED}\$${COLOR_NONE}"
    fi
}

# Determine active Python virtualenv details.
set_virtualenv () {
    if test -z "$VIRTUAL_ENV" ; then
        PYTHON_VIRTUALENV=""
    else
        PYTHON_VIRTUALENV="${LIGHT_GRAY}(`basename \"$VIRTUAL_ENV\"`)${COLOR_NONE}"
    fi
}

# Conditionally set the window title to user@host:dir if we're in an xterm
set_window_title () {
    case "$TERM" in
        xterm*|rxvt*|gnome*)
            WINDOW_TITLE="\[\e]0;\u@\h: \w\a\]"
            ;;
        *)
            WINDOW_TITLE=""
    esac
}

# Set the full bash prompt.
set_bash_prompt () {
    # Set the PROMPT_SYMBOL variable. We do this first so we don't lose the
    # return value of the last command.
    set_prompt_symbol $?

    # Set the PYTHON_VIRTUALENV variable.
    set_virtualenv

    # Set the BRANCH variable.
    if is_git_repository ; then
        set_git_branch
    else
        BRANCH=''
    fi

    set_window_title

    # Set the bash prompt variable.
    PS1="$WINDOW_TITLE${PYTHON_VIRTUALENV}\u@\h:${COLOR_NONE}\w${BRANCH}${PROMPT_SYMBOL} "
}

# Tell bash to execute this function just before displaying its prompt.
PROMPT_COMMAND=set_bash_prompt
