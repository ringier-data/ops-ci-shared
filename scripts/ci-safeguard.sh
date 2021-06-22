#!/bin/bash

set -e

if [[ -z ${ENV} ]]; then
  echo "Error: missing required env ENV"
  exit 1
fi

if [[ -z ${AWS_REGION} ]]; then
  echo "Error: missing required env AWS_REGION"
  exit 2
fi

ACCOUNT_ID=$(aws --region "${AWS_REGION}" sts get-caller-identity --output json | jq -crM '.Account')
if [[ -z ${ACCOUNT_ID} ]] || [[ ${ACCOUNT_ID} == "null" ]]; then
  echo "Fatal error: no active AWS cli session is detected"
  exit 3
fi

# Validate the environment is consistent between the local setting (the wish) and the active remote target (the reality)
TARGET_ENV=$(aws --region "${AWS_REGION}" ssm get-parameter --output json --name /ops-ci/environment 2>/dev/null | jq -crM '.Parameter.Value')
if [[ -z ${TARGET_ENV} ]]; then
  echo "Fatal error: the current AWS account '${ACCOUNT_ID}' does not have environment code setting at /ops-ci/environment"
  exit 4
fi

if [[ ${TARGET_ENV} != "${ENV}" ]]; then
  echo "Fatal error! Your current default AWS account is for '${TARGET_ENV}' but '${ENV}' is specified"
  exit 5
fi
