#!/bin/bash

set -e

cdk_app_dir="cdk-app" # it is expected that the CDK app in a repository is found from this folder
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# shellcheck source=.
. "$dir"/ci-safeguard.sh

if [[ -z ${ENV} ]]; then
  echo "Missing required env ENV"
  exit 1
fi

if [[ $(cat /tmp/is_deploy_flag 2>/dev/null) != "1" ]]; then
  echo "Skipping deploy as FORCE_DEPLOY is not set and branch isn't develop or main"
  exit 0
fi

if [[ ! -d "./${cdk_app_dir}" ]]; then
  echo "Could not find CDK app folder in the repo. You should have a folder called '${cdk_app_dir}' in the root directory of your repo."
  exit 1
fi

if [[ ! -f "${cdk_app_dir}/package.json" ]]; then
  echo "Unable to install dependencies: could not locate ./${cdk_app_dir}/package.json in the repo."
  exit 1
fi

# shellcheck source=.
. "$dir"/ci-include.sh

echo "Changing to CDK app directory..."
cd ${cdk_app_dir}

echo "Installing dependencies..."
npm ci

npm run cdk diff -- --context env=${ENV}

echo "Deploying to env=${ENV}..."
npm run cdk deploy --all --require-approval=never -- --context env=${ENV}
