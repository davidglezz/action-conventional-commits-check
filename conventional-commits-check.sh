#!/bin/bash

set -e

# make newlines the only separator
IFS=$'\n' 

git config --global --add safe.directory /github/workspace

echo "Checking conventional commits between $2 and $1"

custom_pattern="${INPUT_PATTERN}"
merge_commit_regex="^Merge (branch|pull request|remote-tracking branch) .*"

# Get all commit messages from the feature branch that are not in the main branch
commits=($(git log --pretty="%s" origin/$2 ^origin/$1))

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
