# Release Instructions

#### When reviewing a pull request (PR):
* decide whether the changes made PR should be released with the next *minor* or *major* version (see below)
* if a PR should be released with the next major version no additional steps need to be taken. However, please ensure that the PR targets the `master` branch.
* if a PR should be released with the next minor version:
    * make sure the current PR targets the `master` branch.
    * make an identical (or as close as possible) PR that also target the release candidate branch for the upcoming release.
    * add the PR that targets the release candidate branch to the milestone for the upcoming release.

#### When making a major release:
1. merge the `master` branch into the `release` branch and resolve all conflicts.
2. update the Changelog.md files in both the `release` and `master` branches by replacing the `[unreleased]` section with the new release's version number.
3. fully test the `release` branch in development.
4. update the app/MARKUS_VERSION file in the `release` and `master` branches.
5. make a new release targeting the `release` branch (mark it as a pre-release).
6. deploy the new release to a test instance on a production server and test the instance there as well.
7. un-mark the new release as a pre-release

#### When making a minor release:
1. merge the current release candidate branch into the `release` branch (there should be no conflicts).
2. update the Changelog.md file in the both the `release` and `master` branches by creating a new section for the new release and moving all relevant lines from the `[unreleased]` section to this new section.
3. do steps 3-7 from the [major release](#when-making-a-major-release) section above

#### After making any release:
1. close any existing milestones and create a new milestone for the next minor release. For example, if you just released version 1.9.5, make a new milestone named `v1.9.6`.
2. delete the old release candidate branch (if it exists) and create a new release candidate branch based off of the current `release` branch. For example, if you just released version 1.9.5, delete the branch named `v1.9.5.rc` and create a branch named `v1.9.6.rc`
