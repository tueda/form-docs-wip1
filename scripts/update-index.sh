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
DEFAULT_BRANCH=master
DOCUMENT_OUTPUT_DIR=docs

repo_url="${REPOSITORY%.git}"

write_items() {
  dir=$1

  if [ ! -f "$dir/_REVISION" ] || [ ! -f "$dir/_VERSION" ]; then
    return 0
  fi

  if [ -f "$dir/_SKIP" ]; then
    return 0
  fi

  revision=$(cat "$dir/_REVISION")
  version=$(cat "$dir/_VERSION")

  echo

  if [ "$dir" = $DEFAULT_BRANCH ]; then
    echo "## [Nightly Build]($repo_url/tree/$revision)"
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

  write_items $DEFAULT_BRANCH
  for dir in $(printf "%s\n" v* | sort -V -r); do
    write_items "$dir"
  done
} >$DOCUMENT_OUTPUT_DIR/index.md
