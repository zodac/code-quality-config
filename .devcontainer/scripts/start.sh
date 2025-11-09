#!/bin/bash

# Set the permissions for the SSH keys that are mounted from the host system
chmod 700 /root/.ssh && chmod 600 /root/.ssh/*

# Configuring git
# Since the host .gitconfig may be Windows, we have two issues:
# - The `sslBackend` is set to 'schannel' (for Windows)
# - The .gitconfig is read-only (this is always the case when bind mounting a single file from Windows)
# To work around this, we configure git to the an `sslBackend` for Linux, and configure it for local mode
git config --local http.sslBackend gnutl

# Check if there is an update to the repo
if [ -d .git ]; then
    echo "Checking for updates from the remote git repo..."
    
    # Fetch remote info quietly
    git fetch --quiet
    
    # Determine current branch
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -z "${current_branch}" ]; then
        echo "No active branch detected, skipping update check"
        exit 0
    fi
    
    # Determine remote tracking branch
    remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)
    if [ -z "${remote_branch}" ]; then
        echo "No remote tracking branch for '${current_branch}', skipping update check"
        exit 0
    fi
    
    # Compare local vs remote
    local_hash=$(git rev-parse "${current_branch}")
    remote_hash=$(git rev-parse "${remote_branch}")
    
    if [ "${local_hash}" != "${remote_hash}" ]; then
        echo "A new update is available on remote branch '${remote_branch}'"
        read -rp "Would you like to pull the latest changes? [y/N]: " user_reply
        if [[ "${user_reply}" =~ ^[Yy]$ ]]; then
            echo "Pulling latest changes..."
            
            stash_result=$(git stash | xargs)
            if [[ "${stash_result}" == "No local changes to save" ]]; then
                echo ">>> $(basename "${PWD}") has no changes to stash - Rebasing <<<"
                git pull --rebase
            else
                echo ">>> $(basename "${PWD}") stashed - Rebasing <<<"
                git pull --rebase
                echo ">>> $(basename "${PWD}") rebased - New status <<<"
                git stash pop -q
            fi
        fi
    else
        echo "Your branch '${current_branch}' is up-to-date with remote"
    fi
fi
