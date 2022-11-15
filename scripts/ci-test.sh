#!/bin/bash

source_folder=$1

set -e

if [[ -z "$source_folder" ]]; then
  echo "Missing required argument 'source_folder'"
  exit 1
fi

if [[ ${SKIP_TESTS} == "1" ]] || [[ ${SKIP_TESTS} == "true" ]]; then
  echo "WARNING: Skipping tests as SKIP_TESTS flag was set to $SKIP_TESTS"
  exit 0
fi

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# shellcheck source=.
. "$dir"/ci-safeguard.sh
# shellcheck source=.
. "$dir"/ci-include.sh

#
# There are some node.js apps do not require an "npm install" before running the test, for instance, the "npm install" is happening inside
# a Docker container, while all the logic are encapsulated into the "npm run test". For these cases, set SKIP_INSTALL to save some time.
if [[ ${SKIP_INSTALL} == "1" ]] || [[ ${SKIP_INSTALL} == "true" ]]; then
  SKIP_INSTALL=1
else
  SKIP_INSTALL=0
fi

echo "Running tests in $source_folder"
pushd "${source_folder}"

if [[ -f "yarn.lock" ]]; then
  echo "Detected node.js project. Will run tests with yarn..."
  (( SKIP_INSTALL == 0 )) && FORCE_COLOR=0 yarn --emoji false --non-interactive --no-progress --frozen-lockfile
  FORCE_COLOR=0 yarn --emoji false --non-interactive --no-progress test
elif [[ -f "package-lock.json" ]]; then
  echo "Detected node.js project. Will run tests with npm..."
  (( SKIP_INSTALL == 0 )) && npm --no-color --legacy-peer-deps ci
  npm --no-color test
elif [[ -f "requirements.txt" ]]; then
  echo "Detected Python project. Will run pytest tests..."
  (( SKIP_INSTALL == 0 )) && pip install -r requirements.txt
  pip install -U pytest python-dotenv pytest-dependency pytest-ordering
  PYTHONPATH=. pytest -v
else
  echo "ERROR: Could not determine test suite to run."
  exit 1
fi

popd
