#!/bin/bash
#
# List available version tags.
#
# Usage:
#   enum-vers.sh
#
# Note:
#   Requires GNU sort.
#
set -eu
set -o pipefail

REPOSITORY=https://github.com/vermaseren/form.git
MINIMUM_VERSION=4.3.1

git ls-remote --tags $REPOSITORY \
  | awk '{print $2}' \
  | grep -E 'refs/tags/v[0-9]+' \
  | sed -E 's#refs/tags/##; s#\^\{\}##' \
  | sort -V \
  | awk -v min_v="v$MINIMUM_VERSION" '
      $0 == min_v { flag = 1 }
      flag { print }
  '
