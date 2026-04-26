#!/bin/bash

set -e

default_pattern="^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test){1}(\([[:alnum:]._-]+\))?(!)?: ([[:alnum:]])+([[:space:][:print:]]*)$"
pattern="${INPUT_PATTERN:-$default_pattern}"
merge_commit_regex="^Merge (branch|pull request|remote-tracking branch) .*"
target_branch="${1:-${GITHUB_BASE_REF:-}}"
current_branch="${2:-${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}}"

if [ -z "$target_branch" ] || [ -z "$current_branch" ]; then
  echo "Could not determine target/current branch. Set action inputs or run in a pull_request context."
  exit 1
fi

echo "Checking conventional commits between $current_branch and $target_branch"
[ -n "${INPUT_PATTERN}" ] && echo "Using custom pattern: ${INPUT_PATTERN}"

target_ref="refs/remotes/origin/$target_branch"
current_ref="refs/remotes/origin/$current_branch"
current_fetch_ref="refs/heads/$current_branch"

# In pull_request workflows, use refs/pull/<number>/head because the source branch
# may live in a fork and not exist under origin/heads.
if [[ "${GITHUB_REF:-}" =~ ^refs/pull/([0-9]+)/ ]]; then
  pr_number="${BASH_REMATCH[1]}"
  current_ref="refs/remotes/origin/pull/$pr_number/head"
  current_fetch_ref="refs/pull/$pr_number/head"
fi

git config --global --add safe.directory /github/workspace
git fetch --no-tags origin "refs/heads/$target_branch:$target_ref" "$current_fetch_ref:$current_ref"

if ! git rev-parse --verify --quiet "$target_ref" >/dev/null; then
  echo "Could not resolve target branch ref: $target_ref"
  exit 1
fi

if ! git rev-parse --verify --quiet "$current_ref" >/dev/null; then
  echo "Could not resolve current branch ref: $current_ref"
  exit 1
fi

# Get all commit messages from the feature branch that are not in the main branch.
mapfile -t commits < <(git log --pretty="%s" "$target_ref..$current_ref")

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

if [[ "$all_commits_ok" == "true" ]]; then
  echo "commit-checker=true" >> "$GITHUB_OUTPUT"
  exit 0
else
  echo "commit-checker=false" >> "$GITHUB_OUTPUT"
  exit 1
fi
