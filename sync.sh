#!/usr/bin/env bash

set -eo pipefail
shopt -s inherit_errexit

function cleanup() {
  rm -rf ./homebrew-core
}

trap cleanup EXIT

set -x

clone_from='Tue Jul 01 00:00:00 2025 +0000'
last_commit="$(cat ./homebrew_core_commit)"
declare -a commits

REACHED_LAST_COMMIT=0
git clone --shallow-since="$clone_from" https://github.com/Homebrew/homebrew-core.git
while read -r commit
do
  if [[ $REACHED_LAST_COMMIT -gt 0 ]] || [[ "$commit" == "$last_commit" ]]
  then
    REACHED_LAST_COMMIT=1
    continue
  fi
  commits=("$commit" "${commits[@]}")
done < <(
  # shellcheck disable=SC2312
  git -C ./homebrew-core log --format='%H' --perl-regexp --author='^(?!BrewTestBot)' -- ./Formula/git.rb ./Formula/g/git.rb
)

printf 'Applying commits %s\n' "${commits[*]}"

for commit in "${commits[@]}"
do
  if grep "^$commit" ./homebrew_core_ignored_commits
  then
    printf 'Ignoring commit %s as it was found in homebrew_core_ignored_commits\n' "$commit"
    continue
  fi
  if [[ "$(git -C ./homebrew-core show --no-patch --format='%s' "$commit" || true)" == *'update'*'bottle'* ]]
  then
    printf 'Ignoring commit %s as it appears to be a manual bottle update\n' "$commit"
    continue
  fi
  git -C ./homebrew-core show "$commit" -- ./Formula/git.rb ./Formula/g/git.rb | sed 's/git.rb/git-custom.rb/g' | git apply -C1
  printf '%s\n' "$commit" | tee ./homebrew_core_commit
done
