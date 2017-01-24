#!/bin/bash

# Decrypt the private key
openssl aes-256-cbc -K $encrypted_685750fbea84_key -iv $encrypted_685750fbea84_iv -in .travis/isudox_deploy.enc -out ~/.ssh/isudox_deploy -d
# Set the permission of the key
chmod 600 ~/.ssh/isudox_deploy
# Start SSH agent
eval $(ssh-agent)
# Add the private key to the system
ssh-add ~/.ssh/isudox_deploy
# Copy SSH config
cp .travis/ssh_config ~/.ssh/config
# Set Git config
git config --global user.name 'sudoz'
git config --global user.email 'me@isudox.com'
# Clone the repository
git clone --branch master git@github.com:isudox/isudox.github.io.git .deploy_git
# Deploy to GitHub
npm run deploy
