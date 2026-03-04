#!/bin/bash

if [ -z "$RUNNER_URL" ] || [ -z "$RUNNER_TOKEN" ]; then
    echo "Error: RUNNER_URL and RUNNER_TOKEN must be set"
    exit 1
fi

# Set default runner name if not provided
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"

# Fix Docker socket permissions if needed
if [ -S /var/run/docker.sock ]; then
    echo "Fixing Docker socket permissions..."
    sudo chgrp daemon /var/run/docker.sock
    sudo chmod 660 /var/run/docker.sock
fi

# Create _tool directory with proper permissions
echo "Creating _tool directory..."
mkdir -p /actions-runner/_work/_tool
sudo chown -R runner:runner /actions-runner/_work/_tool

./config.sh --url "$RUNNER_URL" --token "$RUNNER_TOKEN" --name "$RUNNER_NAME" --unattended

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "$RUNNER_TOKEN"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
