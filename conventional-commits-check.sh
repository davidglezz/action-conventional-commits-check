#!/bin/bash

set -e

# make newlines the only separator
IFS=$'\n' 

git config --global --add safe.directory /github/workspace

echo "Checking conventional commits between $2 and $1"

custom_pattern="${INPUT_PATTERN}"
merge_commit_regex="^Merge (branch|pull request|remote-tracking branch) .*"

# Get all commit messages from the feature branch that are not in the main branch
target_ref="refs/remotes/origin/$1"
current_ref="refs/remotes/origin/$2"

# Ensure both refs exist locally even when checkout does a shallow/single-ref fetch.
git fetch --no-tags origin \
  "refs/heads/$1:$target_ref" \
  "refs/heads/$2:$current_ref"

if ! git rev-parse --verify --quiet "$target_ref" >/dev/null; then
  echo "Could not resolve target branch ref: $target_ref"
  exit 1
fi

if ! git rev-parse --verify --quiet "$current_ref" >/dev/null; then
  echo "Could not resolve current branch ref: $current_ref"
  exit 1
fi

commits=($(git log --pretty="%s" "$current_ref" "^$target_ref"))

pattern=""
if [ -z "${custom_pattern}" ]; then
  pattern="^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test){1}(\([[:alnum:]._-]+\))?(!)?: ([[:alnum:]])+([[:space:][:print:]]*)$"
else
  echo "Using custom pattern: ${custom_pattern}"
  pattern="${custom_pattern}"
fi

all_commits_ok="true"
for commit in "${commits[@]}"; do
  if [[ $commit =~ $merge_commit_regex ]]; then
    echo "🔘 | $commit"
  elif [[ $commit =~ $pattern ]]; then
    echo "✅ | $commit"
  else
    echo "❌ | $commit"
    all_commits_ok="false"
  fi
done

if [ $all_commits_ok == "true" ]; then
  echo "commit-checker=true" >> $GITHUB_OUTPUT
  exit 0
else
  echo "commit-checker=false" >> $GITHUB_OUTPUT
  exit 1
fi
