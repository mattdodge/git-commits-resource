# Git Commits Resource

Sometimes you want to run a task on every commit in a repository regardless of branch. Tasks like building docker images, running unit tests, linters, etc often need to run on every branch. This is surprisingly difficult to do with Concourse until the [concept of spaces](https://blog.concourse-ci.org/core-roadmap-towards-v10/#where-is-spaces-) arrives.

This resource hopes to resolve that by triggering a new version for each commit. It is influenced by [vito's git-branch-heads resource](https://github.com/vito/git-branch-heads-resource) but that one is deprecated and often hard to reason about in the Concourse UI.

## Installation

Add the following `resource_types` entry to your pipeline:

```yaml
---
resource_types:
- name: git-commits
  type: docker-image
  source: {repository: mattdodge/git-commits-resource}
```

## Source Configuration

All of the options in the [Git resource](https://github.com/concourse/git-resource) are available. These define the repository and how it is cloned/passed to tasks. In addition these properties are available:

* `branches`: *Optional.* An array of branch name filters. If not specified, all branches are tracked.
* `exclude`: *Optional* A Regex for branches to be excluded. If not specified, no branches are excluded.

The `branch` configuration from the original resource is ignored for `check`.


### Example

Resource configuration for a repo with a bunch of branches named `wip-*`:

``` yaml
resources:
- name: my-repo-with-feature-branches
  type: git-commits
  source:
    uri: https://github.com/concourse/atc
    branches: [wip-*]
```
Resource configuration for a repo with `version` and branches beginning with `feature/` filtered out:

``` yaml
resources:
- name: my-repo-with-feature-branches
  type: git-commits
  source:
    uri: https://github.com/concourse/atc
    exclude: version|feature/.*
```

## Behavior


### `check`: Check for changes to all branches.

The repository is cloned (or pulled if already present), the branch heads of each active branch are looked at and ordered by commit time. Any new commits trigger new versions.

Note that it is possible to miss commits if multiple commits are made to a branch in between the time the check occurs. Only the head commit of each branch is considered when the check runs. In general this is ok, as you likely only want to run your tasks on the most recent commit if a branch with many commits is pushed.

If a branch is removed/deleted no new version will be emitted as there is no new commit to consider.

### `in`: Fetch the commit that changed the branch.

This resource delegates entirely to the `in` of the original Git resource, by specifying `source.branch` as the branch that changed, and `version.ref` as the
commit on the branch.

All `params` and `source` configuration of the original resource will be respected.

In addition, the following information is written to the repository's directory:
* `.git/git-commits-resource/branch` - the name of the branch that was pulled


### `out`: No-op.

*Not implemented.*
