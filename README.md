# ops-ci-shared

**Current version: v1.2.2**

This repository hosts the CI/CD shell scripts for projects to be deployed into AWS.

This repo is designed to be included into other repo as a git submodule. To include it:
```shell-script
git submodule add -b main https://github.com/ringier-data/ops-ci-shared.git
```

NOTE: it is important to add submodule using `https` instead of `git` protocol, because the AWS CodeBuild agent does not have an SSH key
to access Github.

This repo does not work without `https://github.com/ringier-data/ops-ci-aws` which is also under MIT license.

The following parameters have to be created at AWS SystemManager Parameter Store:

| Parameter name                        | Type         | Description                                | Comment                                                                              |
|:--------------------------------------|:-------------|:-------------------------------------------|:-------------------------------------------------------------------------------------|
| `/ops-ci/environment`                 | String       | Environment code of the AWS account        | e.g. `dev`, `stg`, `prod`, etc.                                                      |
| `/ops-ci/github-organization`         | String       | Name of Github organization                | e.g. `ringier-data`                                                                  |
| `/ops-ci/github-access-token`         | SecureString | PAT of Github CI/CD user                   | e.g. ghp_1a2B3c4D5e6F7A8b9C0d1E2f3a4B5c6D7e8F                                        |
| `/ops-ci/slack-webhook-notifications` | SecureString | URL of the Slack Incoming Messages Webhook | e.g. https://hooks.slack.com/services/1A2B3C4D5/E6F7G8H9I0J/1k2L3m4n5O6p7Q8s9T0u1V2w |
