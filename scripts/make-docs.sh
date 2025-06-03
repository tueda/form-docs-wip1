#!/bin/bash
#
# Build documentation.
#
# Usage:
#   make-docs.sh OUTPUT-DIR
#   make-docs.sh OUTPUT-DIR REPO-REVISION
#
set -eu
set -o pipefail

REPOSITORY=https://github.com/vermaseren/form.git

# Trap ERR to print the stack trace when a command fails.
# See: https://gist.github.com/ahendrix/7030300
_errexit() {
  local err=$?
  set +o xtrace
  local code="${1:-1}"
  echo "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}: '${BASH_COMMAND}' exited with status $err" >&2
  # Print out the stack trace described by $FUNCNAME
  if [ ${#FUNCNAME[@]} -gt 2 ]; then
    echo "Traceback:" >&2
    for ((i=1;i<${#FUNCNAME[@]}-1;i++)); do
      echo "  [$i]: at ${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]} in function ${FUNCNAME[$i]}" >&2
    done
  fi
  echo "Exiting with status $code" >&2
  exit "$code"
}
trap _errexit ERR
set -o errtrace

# Check the command line arguments.
if [[ $# == 1 ]]; then
  out_dir="$1"
  repo_rev=master
elif [[ $# == 2 ]]; then
  out_dir="$1"
  repo_rev="$2"
else
  echo "Usage:"
  echo "  $(basename "$0") OUTPUT-DIR"
  echo "  $(basename "$0") OUTPUT-DIR REPO-REVISION"
  exit 1
fi

# Convert the output directory to an absolute path.
if [[ "$out_dir" != /* ]]; then
  out_dir="$PWD/$out_dir"
fi

# Create a temporary working directory.
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# Build documentation in the temporary directory.
cd "$tmp_dir"

clean_latex2html() {
  (
    cd "$1"
    rm -f images.aux images.idx images.log images.pdf images.pl images.tex internals.pl labels.pl # WARNINGS
  )
}

git clone $REPOSITORY
cd form
git checkout "$repo_rev"
distname=form-$(./scripts/git-version-gen.sh -r | sed '2q;d' | sed 's/^v//')
autoreconf -i
mkdir build
cd build
../configure --disable-dependency-tracking --disable-scalar --disable-threaded
make pdf
make -C doc/manual latex2html
clean_latex2html doc/manual/manual
make -C doc/devref latex2html
clean_latex2html doc/devref/devref
make -C doc/doxygen html

# Prepare the output directory.
mkdir -p "$out_dir"

# Move the documents.
git rev-parse HEAD >"$out_dir/REVISION"
echo "$distname" >"$out_dir/DISTNAME"
mv doc/manual/manual.pdf "$out_dir/$distname-manual.pdf"
mv doc/devref/devref.pdf "$out_dir/$distname-devref.pdf"
mv doc/doxygen/doxygen.pdf "$out_dir/$distname-doxygen.pdf"
mv doc/manual/manual "$out_dir/manual"
mv doc/devref/devref "$out_dir/devref"
mv doc/doxygen/html "$out_dir/doxygen"
