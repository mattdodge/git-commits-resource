#!/bin/bash

set -e -u

set -o pipefail

export TMPDIR_ROOT=$(mktemp -d /tmp/git-tests.XXXXXX)
trap "rm -rf $TMPDIR_ROOT" EXIT

if [ -d /opt/resource ]; then
  resource_dir=/opt/resource
else
  resource_dir=$(cd $(dirname $0)/../assets && pwd)
fi

run() {
  export TMPDIR=$(mktemp -d ${TMPDIR_ROOT}/git-tests.XXXXXX)

  echo -e 'running \e[33m'"$@"$'\e[0m...'
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

init_repo() {
  (
		local ts=${1-}
    set -e

    cd $(mktemp -d $TMPDIR/repo.XXXXXX)

    git init -q

    # start with an initial commit
    GIT_COMMITTER_DATE="$ts" git \
      -c user.name='test' \
      -c user.email='test@example.com' \
      commit -q --allow-empty -m "init"

    # back to master
    git checkout master

    # print resulting repo
    pwd
  )
}

make_commit_to_file_on_branch() {
  local repo=$1
  local file=$2
  local branch=$3
	local ts=${4-}  # Allow forcing the commit timestamp

  # ensure branch exists
  if ! git -C $repo rev-parse --verify $branch >/dev/null 2>&1; then
    git -C $repo branch $branch master
  fi

  # switch to branch
  git -C $repo checkout -q $branch

  # modify file and commit
  echo x >> $repo/$file
  git -C $repo add $file
  GIT_COMMITTER_DATE="$ts" git -C $repo \
    -c user.name='test' \
    -c user.email='test@example.com' \
    commit -q -m "commit $(wc -l $repo/$file) $RANDOM"

  # output resulting sha
  git -C $repo rev-parse HEAD
}

make_commit_to_branch() {
  make_commit_to_file_on_branch $1 some-file $2 $3
}

check_uri() {
  jq -n '{
    source: {
      uri: $uri
    }
  }' --arg uri "$1" | ${resource_dir}/check | tee /dev/stderr
}

check_uri_branches() {
  jq -n '{
    source: {
      uri: $uri,
      branches: ($branches | split(" "))
    }
  }' --arg uri "$1" --arg branches "$*" | ${resource_dir}/check | tee /dev/stderr
}

check_uri_from() {
  uri=$1

  shift

  branches=$(echo "$@" | jq -R 'split(" ") | map(split("=") | {key: .[0], value: .[1]}) | from_entries')

  jq -n '{
    source: {
      uri: $uri
    },
    version: ({changed: "doesnt-matter"} + $branches)
  }' --arg uri "$uri" --argjson branches "$branches" | ${resource_dir}/check | tee /dev/stderr
}

check_uri_from_ts() {
	uri=$1
  ts=$2

  jq -n '{
    source: {
      uri: $uri
    },
		version: ({ts: $ts, ref: "fakeref", branch:"fakebranch"})
  }' --arg uri "$uri" --arg ts "$ts" | ${resource_dir}/check | tee /dev/stderr
}

check_uri_changed_only() {
  jq -n '{
    source: {
      uri: $uri,
			changed_only: true
    }
  }' --arg uri "$1" | ${resource_dir}/check | tee /dev/stderr
}

get_changed_branch() {
  uri=$1
  dest=$2
  changed=$3

  shift 3

  branches=$(echo "$@" | jq -R 'split(" ") | map(split("=") | {key: .[0], value: .[1]}) | from_entries')

  jq -n '{
    source: {
      uri: $uri
    },
    version: ({changed: $changed} + $branches)
  }' --arg uri "$uri" --arg changed "$changed" --argjson branches "$branches" |
    env GIT_RESOURCE_IN=$(dirname $0)/git-in-stub \
      ${resource_dir}/in "$dest" |
    tee /dev/stderr
}

get_changed_ref() {
  uri=$1
  dest=$2
  branch=$3
  ref=$4
	ts=$5

  jq -n '{
    source: {
      uri: $uri
    },
	version: ({branch: $branch, ref: $ref, ts: $ts})
  }' --arg uri "$uri" --arg ref "$ref" --arg branch "$branch" --arg ts "$ts" |
    env GIT_RESOURCE_IN=$(dirname $0)/git-in-stub \
      ${resource_dir}/in "$dest" |
    tee /dev/stderr
}
