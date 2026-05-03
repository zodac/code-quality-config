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
    
    # Ensure we have an upstream branch
    remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)
    if [ -z "${remote_branch}" ]; then
        echo "No remote tracking branch for '${current_branch}', skipping update check"
        exit 0
    fi
    
    # Check if remote has commits not in local
    behind_count=$(git rev-list --count HEAD..@{u})
    
    if [ "${behind_count}" -gt 0 ]; then
        echo "Remote has ${behind_count} new commit(s) on '${remote_branch}'"
        
        read -rp "Would you like to pull and rebase? [y/N]: " user_reply
        if [[ "${user_reply}" =~ ^[Yy]$ ]]; then
            echo "Updating local branch with remote changes..."
            
            stash_applied=false
            
            # Only stash if needed
            if ! git diff-index --quiet HEAD --; then
                echo "Stashing local changes..."
                git stash push -u -m "auto-stash before rebase"
                stash_applied=true
            fi
            
            echo "Rebasing onto ${remote_branch}..."
            git pull --rebase
            
            if [ "${stash_applied}" = true ]; then
                echo "Restoring stashed changes..."
                git stash pop -q
            fi
            
            echo "Update complete."
        fi
    else
        echo "Your branch '${current_branch}' is up-to-date with remote"
    fi
fi
