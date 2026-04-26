# action-conventional-commits-check
Github action to check that all PR commits follow [conventional commits](https://www.conventionalcommits.org/).

What makes this action different is that it validates commits using local `git` history instead of the GitHub API. Because of that, the repository must be available in the runner (`actions/checkout` is required), and it is compatible with other Git platforms such as Forgejo or Gitea.

Usage example:

```yaml
name: "Conventional Commits Check"
on:
  pull_request:

jobs:
  conventional-commits-check:
    steps:
    - uses: actions/checkout@v4

    - name: Conventional Commits Checker
      uses: davidglezz/action-conventional-commits-check@v2.0.0
```


## Inputs

| Name | Description | Default |
| --- | --- | --- |
| `target-branch` | Target branch to compare against. | `${GITHUB_BASE_REF}` |
| `current-branch` | Current/source branch to validate. | `${GITHUB_HEAD_REF}` |
| `pattern` | POSIX ERE Regex used to validate commit messages. | `^(build\|chore\|ci\|docs\|feat\|fix\|perf\|refactor\|revert\|style\|test){1}(\([[:alnum:]._-]+\))?(!)?: ([[:alnum:]])+([[:space:][:print:]]*)$` |

This action automatically fetches the required branches so checkout with `fetch-depth: 0` is not required. 

In `pull_request` workflows, `target-branch` and `current-branch` are optional. If omitted, they are automatically resolved from the PR context.


If needed, you can still set them explicitly:

```yaml
- name: Conventional Commits Checker
  uses: davidglezz/action-conventional-commits-check@v2.0.0
  with:
      target-branch: ${{ github.event.pull_request.base.ref }}
      current-branch: ${{ github.event.pull_request.head.ref }}
```

## Related projects
- https://github.com/netodevel/conventional-commits-checker/
- https://gist.github.com/marcojahn/482410b728c31b221b70ea6d2c433f0c
