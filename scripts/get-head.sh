#!/bin/bash
#
# Print the SHA of the remote HEAD.
#
# Usage:
#   get-head.sh
#
set -eu
set -o pipefail

REPOSITORY=https://github.com/vermaseren/form.git

git ls-remote $REPOSITORY HEAD | awk '{print $1}'
