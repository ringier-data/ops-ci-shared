#!/bin/bash

set -e

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_NAME=$(basename $(realpath "${dir}/../../"))

# shellcheck source=.
. "$dir"/ci-safeguard.sh

if [[ $(cat /tmp/is_deploy_flag 2>/dev/null) != "1" ]]; then
  if [[ ${AGGRESSIVE_DEVELOPMENT} == "1" ]]; then
    echo "Skipping deploy as FORCE_DEPLOY is not set and branch isn't develop or main"
  else
    echo "Skipping deploy as deployment flag is not set"
  fi
  exit 0
fi

if [[ -z ${ANSIBLE_FOLDERS} ]]; then
  ANSIBLE_FOLDERS="infrastructure"
fi

if [[ -z ${INFRASTRUCTURE_FOLDERS} ]]; then
  INFRASTRUCTURE_FOLDERS=${ANSIBLE_FOLDERS}
fi

if [[ -z ${OPS_CI_AWS_BRANCH} ]]; then
  OPS_CI_AWS_BRANCH="main"
fi

if [[ -z ${ANSIBLE_VERBOSITY} ]]; then
  ANSIBLE_VERBOSITY="1"
fi

# shellcheck source=.
. "$dir"/ci-include.sh

MODULES=("${INFRASTRUCTURE_FOLDERS//,/ }")

# check that each module contains something deployable
for module in "${MODULES[@]}"; do
  pushd "${module}"
  if ! { [[ -f "./package.json" && -f "./package-lock.json" ]] || [[ -f "./playbook.yml" ]]; }; then
    echo "No deployable unit found in ./${module}. Nothing will be deployed."
    exit 1
  fi
  popd
done

for module in "${MODULES[@]}"; do
  echo Deploying "${module}" module...
  pushd "${module}"

  if [[ CHECK_CLOUDFORMATION -eq  "1" ]]; then
    # check that CloudFormation stacks are up to date with the origin
    if [[ $ENV == "dev" ]]; then
      origin_branch="develop"
    else
      origin_branch="main"
    fi
    software_component=$(cat playbook.yml | grep 'software_component' | awk '{ print $2}' | sed "s/\"//g" | sed "s/'//g")
    git_commits=($(git rev-parse origin/$origin_branch))
    for stack in $(aws cloudformation list-stacks --output text --query 'StackSummaries[?contains(StackName, `'$software_component'`)].[StackName]'); do
    git_commit=$(aws cloudformation describe-stacks --stack-name $stack --query 'Stacks[0].Tags[?contains(Key, `GitCommit`)][].Value' | jq -r '.[0]')
    if [[ ! " ${git_commits[*]} " =~ " ${git_commit} " ]]; then
        git_commits+=($git_commit)
    fi
    done

    if [[ ${#git_commits} -gt 1 ]]; then
        cf_commits_str=$(printf "%s\n"  "${git_commits[@]:1}")
        read -p "origin/develop is at $(git rev-parse origin/develop). While on CloudFormation ${cf_commits_str} is deployed. Are you sure to continue? [yY] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Exiting..."
            exit 1
        fi
    fi
  fi

  if [[ -f "./package.json" && -f "./package-lock.json" ]]; then
    npm --no-color ci
    npm --no-color run cdk diff -- --context env=${ENV}
    npm --no-color run cdk deploy -- --all --require-approval=never --context env=${ENV}
  else
    if [[ ${OPS_CI_AWS_BRANCH} != "main" || ${REPO_NAME} == "ops-ci-codebuild-image" ]]; then
      # install the collection for CI/CD (the main branch is already baked into the CodeBuild custom image)
      ansible-galaxy collection install --force git+https://github.com/ringier-data/ops-ci-aws.git,"${OPS_CI_AWS_BRANCH}"
    fi

    if [[ -f "requirements.txt" ]]; then
      pip install -r requirements.txt
    fi
    ansible-playbook -e env="$ENV" playbook.yml
  fi

  popd
done
