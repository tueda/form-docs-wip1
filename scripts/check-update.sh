#!/bin/bash
#
# Check for updates.
#
# Usage:
#   check-update.sh
#
set -eu
set -o pipefail

REPOSITORY=https://github.com/form-dev/form.git
DEFAULT_BRANCH=master
MINIMUM_VERSION=4.3.1
DOCUMENT_OUTPUT_DIR=docs

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
err=false

get_head() {
  git ls-remote $REPOSITORY $DEFAULT_BRANCH | awk '{print $1}'
}

enum_versions() {
  git ls-remote --tags $REPOSITORY |
    awk '{print $2}' |
    grep -E 'refs/tags/v[0-9]+' |
    sed -E 's#refs/tags/##; s#\^\{\}##' |
    sort -V |
    awk -v min_v="v$MINIMUM_VERSION" '
        $0 == min_v { flag = 1 }
        flag { print }
    '
}

git_commit() {
  git add -u
  if [ -n "$(git status --porcelain)" ]; then
    if ! pre-commit run; then
      git add -u
      pre-commit run
    fi
    git commit -m "docs(auto): update $1"
  fi
}

make_docs() {
  if [ -f "$1/_SKIP" ]; then
    return 0
  fi
  if [ -n "$(git status --porcelain)" ]; then
    echo 'error: working directory is dirty' >&2
    exit 1
  fi
  tmp_dir="$1.$$"
  if ! "$script_dir"/make-docs.sh "$tmp_dir" "$2"; then
    err=:
    rm -fR "$tmp_dir"
    return 0
  fi
  rm -fR "$1"
  mv "$tmp_dir" "$1"
  "$script_dir"/update-index.sh
  git add "$1"
  if ! git_commit "$2"; then
    git stash
    err=:
  fi
  return 0
}

# Check for each version.
for v in $(enum_versions); do
  if [ ! -f $DOCUMENT_OUTPUT_DIR/"$v"/_REVISION ]; then
    make_docs $DOCUMENT_OUTPUT_DIR/"$v" "$v"
  fi
done

# Check for the default branch.
ok=false
if [ -f $DOCUMENT_OUTPUT_DIR/$DEFAULT_BRANCH/_REVISION ]; then
  if [ "$(get_head)" == "$(cat $DOCUMENT_OUTPUT_DIR/$DEFAULT_BRANCH/_REVISION)" ]; then
    ok=:
  fi
fi
if ! $ok; then
  make_docs $DOCUMENT_OUTPUT_DIR/$DEFAULT_BRANCH $DEFAULT_BRANCH
fi

# Update the main page.
"$script_dir"/update-index.sh
git_commit 'index'

if $err; then
  exit 1
fi
