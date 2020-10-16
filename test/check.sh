#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

ts0=1602177520
ts1=1602177521
ts2=1602177522
ts3=1602177523
ts4=1602177524
ts5=1602177525

it_can_check_from_no_version() {
  local repo=$(init_repo $ts0)

  local refmaster1=$(git -C $repo rev-parse master)

  local refa1=$(make_commit_to_branch $repo branch-a $ts1)
  local refb1=$(make_commit_to_branch $repo branch-b $ts2)

	# Should grab the latest branch only
  check_uri $repo | jq -e '
    . == [{
			branch: "branch-b",
			ref: $refb1,
			ts: $ts2
    }]
  ' --arg refb1 "$refb1" --arg ts2 "$ts2"
}

it_can_check_from_version() {
  local repo=$(init_repo $ts0)

  local refmaster1=$(git -C $repo rev-parse master)

  local refa1=$(make_commit_to_branch $repo branch-a $ts1)
  local refb1=$(make_commit_to_branch $repo branch-b $ts2)

  check_uri_from_ts $repo $ts1 | jq -e '
    . == [{
			branch: "branch-a",
			ref: $refa1,
			ts: $ts1
    },{
			branch: "branch-b",
			ref: $refb1,
			ts: $ts2
    }]
  ' --arg refa1 "$refa1" --arg refb1 "$refb1" --arg ts1 "$ts1" --arg ts2 "$ts2"
}

it_can_check_from_updated_branch() {
  local repo=$(init_repo $ts0)

  local refmaster1=$(git -C $repo rev-parse master)

  local refa1=$(make_commit_to_branch $repo branch-a $ts1)
  local refb1=$(make_commit_to_branch $repo branch-b $ts2)

  local refa2=$(make_commit_to_branch $repo branch-a $ts3)
  local refb2=$(make_commit_to_branch $repo branch-b $ts4)

	# Make sure we include the original version so we have history
  check_uri_from_ts $repo $ts1 | jq -e '
    . == [{
			branch: "branch-a",
			ref: $refa2,
			ts: $ts3
    },{
			branch: "branch-b",
			ref: $refb2,
			ts: $ts4
    }]
  ' --arg refa2 "$refa2" --arg refb2 "$refb2" --arg ts3 "$ts3" --arg ts4 "$ts4"
}

run it_can_check_from_no_version
run it_can_check_from_version
run it_can_check_from_updated_branch
