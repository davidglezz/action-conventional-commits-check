#!/bin/bash

set -e

# make newlines the only separator
IFS=$'\n' 

git config --global --add safe.directory /github/workspace

target_branch="${1:-}"
current_branch="${2:-}"

if [ -z "$target_branch" ]; then
  target_branch="${GITHUB_BASE_REF:-}"
fi

if [ -z "$current_branch" ]; then
  if [ -n "${GITHUB_HEAD_REF:-}" ]; then
    current_branch="${GITHUB_HEAD_REF}"
  else
    current_branch="${GITHUB_REF_NAME:-}"
  fi
fi

if [ -z "$target_branch" ] || [ -z "$current_branch" ]; then
  echo "Could not determine target/current branch. Set action inputs or run in a pull_request context."
  exit 1
fi

echo "Checking conventional commits between $current_branch and $target_branch"

custom_pattern="${INPUT_PATTERN}"
merge_commit_regex="^Merge (branch|pull request|remote-tracking branch) .*"

# Get all commit messages from the feature branch that are not in the main branch.
# For pull_request workflows, prefer refs/pull/<number>/head as it works with forks
# and avoids edge cases with branch names.
target_ref="refs/remotes/origin/$target_branch"
current_ref="refs/remotes/origin/$current_branch"

if [[ "${GITHUB_REF:-}" =~ ^refs/pull/([0-9]+)/ ]]; then
  pr_number="${BASH_REMATCH[1]}"
  current_ref="refs/remotes/origin/pull/$pr_number/head"

  git fetch --no-tags origin \
    "refs/heads/$target_branch:$target_ref" \
    "refs/pull/$pr_number/head:$current_ref"
else
  # Fallback for non-pull_request workflows.
  git fetch --no-tags origin \
    "refs/heads/$target_branch:$target_ref" \
    "refs/heads/$current_branch:$current_ref"
fi

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
