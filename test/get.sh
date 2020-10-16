#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

ts0=1602177520
ts1=1602177521
ts2=1602177522

it_can_get_version() {
  local dest=$TMPDIR/destination

  mkdir $dest

  local repo=$(init_repo $ts0)

  local refmaster1=$(git -C $repo rev-parse master)

  local refa1=$(make_commit_to_branch $repo branch-a $ts1)
  local refb1=$(make_commit_to_branch $repo branch-b $ts2)

  get_changed_ref $repo $dest "branch-a" $refa1 $ts1 | jq -e '
    . == {
      destination: $dest,
      request: {
        source: {
          uri: $repo,
          branch: $branch,
        },
        version: {
          ref: $ref
        }
      },
      version: {
        "branch": $branch,
        "ref": $ref,
        "ts": $ts
      }
    }
  ' --arg dest "$dest" \
    --arg repo "$repo" \
    --arg branch "branch-a" \
    --arg ref "$refa1" \
    --arg ts "$ts1"
}

run it_can_get_version
