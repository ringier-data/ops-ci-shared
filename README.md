# rcplus-ci-shared

**Current version: 0.0.3**

This repository hosts the CI/CD shell scripts for projects to be deployed into AWS.

This is the only repo which has only a `main` branch. It is designed to be included into other repo as a git submodule. To include it:
```shell-script
git submodule add -b main https://github.com/ringier-data/rcplus-ci-shared.git
```

NOTE: it is important to add submodule using `https` instead of `git` protocol. Because the AWS CodeBuild agent does not have an SSH key  
to access Github.
