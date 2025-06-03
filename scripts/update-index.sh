#!/bin/bash
#
# List available version tags.
#
# Usage:
#   update-index.sh
#
# Note:
#   Requires GNU sort.
#
set -eu
set -o pipefail

{
  echo '---'
  echo 'title: FORM documentation'
  echo 'layout: default'
  echo '---'
  echo '# FORM documentation'
} >docs/index.md
