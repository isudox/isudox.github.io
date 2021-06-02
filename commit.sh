#!/bin/sh

git add --all
git add public
git add theme/nova
git commit --author="isudox <isudox@gmail.com>" -m "commit local files and submodules changes."
git push origin source
