#!/usr/bin/env bash

set -eo pipefail
shopt -s inherit_errexit

function cleanup() {
  rm -rf ./homebrew-core
}

trap cleanup EXIT

set -x

clone_from='Wed Apr 26 03:41:44 2023 +0800'
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
  git -C ./homebrew-core show "$commit" -- ./Formula/git.rb ./Formula/g/git.rb | sed 's/git.rb/git-custom.rb/g' | git apply -C1
  printf '%s\n' "$commit" | tee ./homebrew_core_commit
done
