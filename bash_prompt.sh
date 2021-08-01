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

# Examples to move into tests:
# git 2.15.0
# $ git status
# On branch master
# Your branch is up to date with 'origin/master'.
#
# nothing to commit, working tree clean
#
# $ git status
# On branch master
# Your branch is ahead of 'origin/master' by 1 commit.
#   (use "git push" to publish your local commits)
#
# nothing to commit, working tree clean
#
# $ git status
# On branch master
# Your branch is behind 'origin/master' by 4 commits, and can be fast-forwarded.
#   (use "git pull" to update your local branch)
#
# nothing to commit, working tree clean
#




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
DIM="\[\e[2m\]"

join_by () { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

# Detect whether the current directory is a git repository.
is_git_repository () {
    [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1
}

# Determine the branch/state information for this git repository.
set_git_branch () {
    # Capture the output of the "git status" command.
    git_status="$(git status 2> /dev/null)"

    # Set color based on clean/staged/dirty.
    status_pattern="working (directory|tree) clean"
    if [[ ${git_status} =~ ${status_pattern} ]]; then
        state="${GREEN}"
    elif [[ ${git_status} =~ "Changes to be committed" ]]; then
        state="${YELLOW}"
    else
        state="${LIGHT_RED}"
    fi

    local remote
    # Set arrow icon based on status against remote.
    remote_pattern="(# |)Your branch is (\w*) (of|by|)"
    if [[ ${git_status} =~ ${remote_pattern} ]]; then
        if [[ ${BASH_REMATCH[2]} == "ahead" ]]; then
            remote="↑"
        elif [[ ${BASH_REMATCH[2]} == "behind" ]]; then
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
    detacted_pattern="(# |)([^ ]*) detached at (\S*)"
    rebase_pattern="You are currently rebasing branch '([^']*)' on '([^']*)'."
    if [[ ${git_status} =~ ${branch_pattern} ]]; then
        branch=${BASH_REMATCH[2]}
    elif [[ ${git_status} =~ ${detacted_pattern} ]]; then
        branch="${YELLOW}↮${state}${BASH_REMATCH[3]}"
    elif [[ ${git_status} =~ ${rebase_pattern} ]]; then
        branch="♽${BASH_REMATCH[1]}→${BASH_REMATCH[2]}"
    else
        branch=""
    fi

    # See https://github.com/git/git/commit/8976500cbbb13270398d3b3e07a17b8cc7bff43f
    # as to why do this to avoid executing code in branch names.
    __git_ps1_branch_name=$branch
    branch="\${__git_ps1_branch_name}"

    # Set the final branch string.
    BRANCH="${state}(${branch})${remote}${COLOR_NONE}"
}

# Return the prompt symbol to use, colorized based on the return value of the
# previous command.
set_prompt_symbol () {
    if [ $? -eq 0 ] ; then
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
        xterm*|rxvt*|gnome*|alacritty)
            WINDOW_TITLE="\[\e]0;\u@\h: \w\a\]"
            ;;
        *)
            WINDOW_TITLE=""
    esac
}

# Set the full bash prompt.
set_bash_prompt () {
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
    PS1="$WINDOW_TITLE${DIM}\t${COLOR_NONE} ${PYTHON_VIRTUALENV}\u@\h:${COLOR_NONE}\w${BRANCH}${PROMPT_SYMBOL} "
}

# Tell bash to execute this function just before displaying its prompt.
our_prompt_command=$(join_by ';' "${GIT_BASH_PROMPT_BEFORE_COMMAND:-:}" set_bash_prompt "${GIT_BASH_PROMPT_AFTER_COMMAND:-:}")
if [[ -v PROMPT_COMMAND ]]; then
    PROMPT_COMMAND="set_prompt_symbol;$PROMPT_COMMAND;$our_prompt_command"
else
    PROMPT_COMMAND="set_prompt_symbol;$our_prompt_command"
fi
