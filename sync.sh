#!/usr/bin/env bash

set -eo pipefail
shopt -s inherit_errexit

function cleanup() {
    rm -rf ./homebrew-core
}

trap cleanup EXIT

set -x

last_date="$(cat ./homebrew_core_date)"
last_commit="$(cat ./homebrew_core_commit)"

git clone --shallow-since="$last_date" https://github.com/Homebrew/homebrew-core.git
git -C ./homebrew-core log --reverse --format='%H' --since='Wed Apr 26 03:41:44 2023 +0800' --perl-regexp --author='^(?!BrewTestBot)' -- ./Formula/git.rb | grep -v "$last_commit" | while read -r commit; do
    git -C ./homebrew-core show "$commit" | sed 's/git.rb/git-custom.rb/g' | git apply -C1
    git -C ./homebrew-core log -1 --format='%ad' "$commit" | tee ./homebrew_core_date
    printf '%s\n' "$commit" | tee ./homebrew_core_commit
done
