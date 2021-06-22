#!/bin/bash

set -e

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

if [[ -z ${ANSIBLE_FOLDERS} ]]; then
  ANSIBLE_FOLDERS="infrastructure"
fi

# shellcheck source=.
. "$dir"/ci-include.sh

pip --quiet --disable-pip-version-check --no-color install ansible boto3 requests pyyaml awscli netaddr

# install the collection for CI/CD
ansible-galaxy collection install --force git+https://github.com/ringier-data/ops-ci-aws.git,main

MODULES=("${ANSIBLE_FOLDERS//,/ }")

for module in "${MODULES[@]}"; do
  echo Deploying "${module}" module...
  pushd "${module}"

  if [[ -f "requirements.txt" ]]; then
    pip install -r requirements.txt
  fi

  if [[ -f "playbook.yml" ]]; then
    ansible-playbook -e env="$ENV" -v playbook.yml
  else
    echo "Could not find playbook.yml!"
    exit 1
  fi

  popd
done
