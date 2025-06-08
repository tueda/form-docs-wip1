#!/bin/bash
#
# Update the main page.
#
# Usage:
#   update-index.sh
#
set -eu
set -o pipefail

REPOSITORY=https://github.com/form-dev/form.git
DEVELOPMENT_BRANCHES='master 4.3'
MINIMUM_VERSION=4.3.1
EXCLUDE='v5.0.0-beta.1'
DOCUMENT_OUTPUT_DIR=docs

repo_url="${REPOSITORY%.git}"

enum_versions() {
  printf "%s\n" v* |
    sort -V |
    awk -v min_v="v$MINIMUM_VERSION" '
        $0 == min_v { flag = 1 }
        flag { print }
    ' | sort -V -r
}

write_items() {
  dir=$1

  if [ ! -f "$dir/_REVISION" ] || [ ! -f "$dir/_VERSION" ]; then
    return 0
  fi

  for e in $EXCLUDE; do
    if [ "$1" == "$e" ]; then
      return 0
    fi
  done

  if [ -f "$dir/_SKIP" ]; then
    return 0
  fi

  revision=$(cat "$dir/_REVISION")
  version=$(cat "$dir/_VERSION")

  echo

  if [[ $dir != v* ]]; then
    echo "## [Nightly Build ($dir)]($repo_url/tree/$revision)"
  else
    echo "## [$version]($repo_url/releases/tag/v$version)"
  fi

  if [ -d "$dir/manual" ] && ! [ -f "$dir/manual/_SKIP" ]; then
    echo "- [FORM $version Reference manual]($dir/manual) (also in [PDF]($dir/form-$version-manual.pdf) or [an HTML tarball]($dir/form-$version-manual-html.tar.gz))"
  fi
  if [ -d "$dir/devref" ] && ! [ -f "$dir/devref/_SKIP" ]; then
    echo "- [FORM $version Developer's reference manual]($dir/devref) (also in [PDF]($dir/form-$version-devref.pdf) or [an HTML tarball]($dir/form-$version-devref-html.tar.gz))"
  fi
  if [ -d "$dir/doxygen" ] && ! [ -f "$dir/doxygen/_SKIP" ]; then
    echo "- [FORM $version API reference]($dir/doxygen) (also in [PDF]($dir/form-$version-doxygen.pdf) or [an HTML tarball]($dir/form-$version-doxygen-html.tar.gz))"
  fi
}

{
  echo '---'
  echo 'layout: default'
  echo '---'

  cd docs

  for b in $DEVELOPMENT_BRANCHES; do
    write_items "$b"
  done

  for dir in $(enum_versions); do
    write_items "$dir"
  done
} >$DOCUMENT_OUTPUT_DIR/index.md
