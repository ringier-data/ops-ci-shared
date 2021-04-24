#!/bin/bash

set -e

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# shellcheck source=.
. "$dir"/ci-safeguard.sh

if [[ -f /tmp/is_deploy_flag ]]; then
  rm /tmp/is_deploy_flag
fi

if [[ ${CODEBUILD_WEBHOOK_HEAD_REF} == "refs/heads/develop" ]] ||
  [[ ${CODEBUILD_WEBHOOK_HEAD_REF} == "refs/heads/master" ]] ||
  [[ ${FORCE_DEPLOY} == "1" ]] ||
  [[ ${FORCE_DEPLOY} == "true" ]]; then
  echo "1" > /tmp/is_deploy_flag
  echo CODEBUILD_WEBHOOK_HEAD_REF=\""${CODEBUILD_WEBHOOK_HEAD_REF}"\", FORCE_DEPLOY=\""${FORCE_DEPLOY}"\". Will deploy.
else
  echo CODEBUILD_WEBHOOK_HEAD_REF=\""${CODEBUILD_WEBHOOK_HEAD_REF}"\", FORCE_DEPLOY=\""${FORCE_DEPLOY}"\". Will not deploy.
fi

# shellcheck disable=SC2046
echo /tmp/is_deploy_flag: \"$(cat /tmp/is_deploy_flag 2>/dev/null)\"

# Setup npmrc
if [[ ! -f ~/.npmrc ]]; then
  echo "Creating ~/.npmrc"
  github_token=$(aws --region "$AWS_REGION" ssm get-parameter --output json --name "/rcplus/ci/github-access-token" --with-decryption | jq -crM '.Parameter.Value')
  echo "//npm.pkg.github.com/:_authToken=$github_token" >>~/.npmrc
  echo "@ringier-data:registry=https://npm.pkg.github.com" >>~/.npmrc
else
  echo "Skipping ~/.npmrc as already exists"
fi

# Login into Docker/ECR
registry_uri=$(aws --region "$AWS_REGION" sts get-caller-identity --output json | jq -r '.Account').dkr.ecr.${AWS_REGION}.amazonaws.com
password=$(aws --region "$AWS_REGION" ecr get-login-password 2>/dev/null)
if [[ -z ${password} ]]; then
    echo "No credential retrieved. This is ok if this is the very first run at a new AWS account."
else
    echo "$password" | docker login --username AWS --password-stdin "$registry_uri"
fi
