#!/bin/sh

git add --all
git add public
git add theme/nova
git commit -m 'commit local files and submodules changes.'
git push origin source
