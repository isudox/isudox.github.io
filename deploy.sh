#!/bin/sh

# If a command fails then the deploy stops
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

cd public
git checkout master
cd ..

# Build the project.
hugo # if using a theme, replace with `hugo -t <YOURTHEME>`

# Go To Public folder
cd public

# Checkout to master and add changes.
git checkout master
git add .

# Commit if there're changes
if [[ `git status --porcelain` ]]; then
  msg="rebuilding site $(date)"
  if [ -n "$*" ]; then
    msg="$*"
  fi
  git commit --author="isudox <isudox@gmail.com>" -m "$msg"
  git push origin master
else
  echo "no changes"
fi

cd ../themes/nova
# Commit if there're changes
if [[ `git status --porcelain` ]]; then
  msg="commit nova theme changes $(date)"
  if [ -n "$*" ]; then
    msg="$*"
  fi
  git commit --author="isudox <isudox@gmail.com>" -m "$msg"
  git push origin master
else
  echo "no changes"
fi

cd ../..
git add --all
git commit --author="isudox <isudox@gmail.com>" -m "commit local files and submodules changes."
git push origin source


