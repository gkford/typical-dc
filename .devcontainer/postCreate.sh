#!/bin/bash

# Future use script

# Install aider-chat using pip
pip install aider-chat

# Fetch and add the .aider.conf.yml to the root of the repo
curl -o .aider.conf.yml https://raw.githubusercontent.com/paul-gauthier/aider/main/aider/website/assets/sample.aider.conf.yml

# Add *.aider, .aider.conf.yml, node_modules, and .env.local to .gitignore if not already present
if ! grep -qx "*.aider" .gitignore; then
    echo "*.aider" >> .gitignore
fi
if ! grep -qx ".aider.conf.yml" .gitignore; then
    echo ".aider.conf.yml" >> .gitignore
fi
if ! grep -qx ".env.local" .gitignore; then
    echo ".env.local" >> .gitignore
fi
if ! grep -qx "node_modules" .gitignore; then
    echo "node_modules" >> .gitignore
fi

# Install project dependencies with Yarn
yarn install

echo "Post-create script has been executed."
