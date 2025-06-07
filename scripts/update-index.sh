#!/bin/bash
#
# Update the main page.
#
# Usage:
#   update-index.sh
#
# Note:
#   Requires GNU sort.
#
set -eu
set -o pipefail

REPOSITORY=https://github.com/vermaseren/form.git
DEFAULT_BRANCH=master

repo_url="${REPOSITORY%.git}"

write_items() {
  dir=$1

  if [ ! -f "$dir/REVISION" ]; then
    return 0
  fi

  revision=$(cat "$dir/REVISION")
  version=$(cat "$dir/VERSION")

  echo

  if [ "$dir" = $DEFAULT_BRANCH ]; then
    echo "## [Nightly Build]($repo_url/tree/$revision)"
  else
    echo "## [$version]($repo_url/tree/v$version)"
  fi
}

{
  echo '---'
  echo 'title: FORM documentation'
  echo 'layout: default'
  echo '---'
  echo '# FORM documentation'

  cd docs

  write_items $DEFAULT_BRANCH
  for dir in $(printf "%s\n" v* | sort -V -r); do
    write_items "$dir"
  done
} >docs/index.md
