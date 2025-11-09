#!/bin/bash
##########
# System
##########

# Check for completion files and load into shell session
env_files=(
    "${HOME}/.bash_completion"
)
for env_file in "${env_files[@]}"; do
    if [[ -f "${env_file}" ]]; then
        # shellcheck disable=SC1090
        source "${env_file}"
    fi
done

###########
# git
###########
alias add='git add'
alias addall='git add -A'
alias diff='git diff --word-diff'
alias log='git log'
alias save='git stash save'
alias status='git status'

# Undoes the last commit, and moves the files back into staging
# Does NOT undo the changes on your local machine
uncommit() {
    git reset --soft HEAD^
}

# Pull latest code from remote branch
rebase() {
    git pull --rebase
}

# Reset local repo to remote branch
reset() {
    current_branch=$(git branch --show-current)
    git reset --hard origin/"${current_branch}"
}

# Resets local repo to remote branch, then pull latest code
rrebase() {
    reset
    rebase
}

# Adds all unstaged changes, creates a new commit, and pushes
# Should only be used when pushing a new change
commitq() {
    if [[ "$#" -ne 1 ]]; then
        _fatal "No commit name provided!"
    fi
    
    addall
    git commit -m "${1}"
    git push
}

# Stashes local changes (if any), rebases repo, then pops the stashed changes
stash() {
    _info ">>> Stashing $(basename "${PWD}") - Old status <<<"
    git status
    stash_result=$(git stash | xargs)
    
    if [[ "${stash_result}" == "No local changes to save" ]]; then
        _warning ">>> $(basename "${PWD}") has no changes to stash - Rebasing <<<"
        rebase
    else
        _debug ">>> $(basename "${PWD}") stashed - Rebasing <<<"
        rebase
        _debug ">>> $(basename "${PWD}") rebased - New status <<<"
        git stash pop -q
    fi
    
    git status
}

##################
# Print methods
##################

# Only execute if the shell is interactive and $TERM is set
# Needed when using rsync to another server which is non-interactive
if [[ -t 1 ]] && [[ -n "${TERM}" ]]; then
    BLACK=$(tput setaf 0)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    RESET=$(tput sgr0)
fi

# Cyan
_trace() {
    printf "\n${CYAN}%s${RESET}\n" "$@"
}
_trace_slim() {
    printf "${CYAN}%s${RESET}\n" "$@"
}
_trace_slim_f() {
    printf "${CYAN}%s${RESET}" "$@"
}

# Blue
_debug() {
    printf "\n${BLUE}%s${RESET}\n" "$@"
}
_debug_slim() {
    printf "${BLUE}%s${RESET}\n" "$@"
}
_debug_slim_f() {
    printf "${BLUE}%s${RESET}" "$@"
}

# White
_info() {
    printf "\n${WHITE}%s${RESET}\n" "$@"
}
_info_slim() {
    printf "${WHITE}%s${RESET}\n" "$@"
}
_info_slim_f() {
    printf "${WHITE}%s${RESET}" "$@"
}

# Green
_success() {
    printf "\n${GREEN}%s${RESET}\n" "$@"
}
_success_slim() {
    printf "${GREEN}%s${RESET}\n" "$@"
}
_success_slim_f() {
    printf "${GREEN}%s${RESET}" "$@"
}

# Magenta
_highlight() {
    printf "\n${MAGENTA}%s${RESET}\n" "$@"
}
_highlight_slim() {
    printf "${MAGENTA}%s${RESET}\n" "$@"
}
_highlight_slim_f() {
    printf "${MAGENTA}%s${RESET}" "$@"
}

# Yellow
_warning() {
    printf "\n${YELLOW}%s${RESET}\n" "$@"
}
_warning_slim() {
    printf "${YELLOW}%s${RESET}\n" "$@"
}
_warning_slim_f() {
    printf "${YELLOW}%s${RESET}" "$@"
}

# Black
_dark() {
    printf "\n${BLACK}%s${RESET}\n" "$@"
}
_dark_slim() {
    printf "${BLACK}%s${RESET}\n" "$@"
}
_dark_slim_f() {
    printf "${BLACK}%s${RESET}" "$@"
}

# Red
_error() {
    printf "\n${RED}%s${RESET}\n" "$@"
}
_error_slim() {
    printf "${RED}%s${RESET}\n" "$@"
}
_error_slim_f() {
    printf "${RED}%s${RESET}" "$@"
}

# Red and kills command
_fatal() {
    _error "$@"
    kill -SIGINT $$ 2>/dev/null
    exit 1
}
_fatal_slim() {
    _error_slim "$@"
    kill -SIGINT $$ 2>/dev/null
    exit 1
}
_fatal_slim_f() {
    _error_slim_f "$@"
    kill -SIGINT $$ 2>/dev/null
    exit 1
}

#############################################################################

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# Only run 'bind' and if the shell is interactive
if [[ $- =~ i ]]; then
    # Used to ensure each completion suggestion is listed on its own line
    bind "set completion-display-width 0"
    # Only works for built-in completion (not custom-defined ones, those are specifying in .bash_completion)
    bind "set completion-ignore-case on"
    # If there are some partial matches, even if a full match is ambiguous, it will complete as much as it can ('a<tab>' when 'abcd' and 'abce' are options will complete to 'abc')
    bind "set show-all-if-ambiguous on"
else
    export TERM=dumb # Don't set TERM if non-interactive
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTFILE=/root/.bash_history
export HISTSIZE=10000
export HISTFILESIZE=20000
# After each command, write it immediately to the history
PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Terminal prompt
# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi
# Date/time
# PS1='[\D{%Y-%m-%d %H:%M:%S}] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# Time only
PS1='[\D{%H:%M:%S}] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

if [ -x /usr/bin/dircolors ]; then
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi
