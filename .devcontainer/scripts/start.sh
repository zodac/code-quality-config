#!/bin/bash

# Set the permissions for the SSH keys that are mounted from the host system
chmod 700 /root/.ssh && chmod 600 /root/.ssh/*

# Configuring git
# Since the host .gitconfig may be Windows, we have two issues:
# - The `sslBackend` is set to 'schannel' (for Windows)
# - The .gitconfig is read-only (this is always the case when bind mounting a single file from Windows)
# To work around this, we configure git to the an `sslBackend` for Linux, and configure it for local mode
git config --local http.sslBackend gnutl
