# action-conventional-commits-check
Github action to check that all PR commits follow [conventional commits](https://www.conventionalcommits.org/).

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
      uses: davidglezz/action-conventional-commits-check@v1.0.0
      with:
          target-branch: ${{ github.event.pull_request.base.ref }}
          current-branch: ${{ github.event.pull_request.head.ref }}
```

## Related projects
- https://github.com/netodevel/conventional-commits-checker/
- https://gist.github.com/marcojahn/482410b728c31b221b70ea6d2c433f0c
