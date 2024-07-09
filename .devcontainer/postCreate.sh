#!/bin/bash

# Add *.aider, .aider.conf.yml, node_modules, and .env.local to .gitignore if not already present
if ! grep -qx "*.aider" .gitignore; then
    echo "*.aider" >> .gitignore
fi
if ! grep -qx ".env.local" .gitignore; then
    echo ".env.local" >> .gitignore
fi
if ! grep -qx "node_modules" .gitignore; then
    echo "node_modules" >> .gitignore
fi

# Install aider-chat using pip
pip install aider-chat

# Install project dependencies with Yarn
yarn install

echo "Post-create script has been executed."
