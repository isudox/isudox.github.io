#!/bin/sh

git add --all
git add public
git add theme/nova
git commit -m 'commit submodules change.'
git push origigin source
