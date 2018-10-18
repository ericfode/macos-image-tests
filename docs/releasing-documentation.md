# Releasing image documentation

When an image has been staged in production, we then need to run final image
tests, generate documentation, and then release it for wider consumption.

This repository handles lightweight image smoke testing, and documentation generation.

1) Create a new branch named `release/xcode-{version}`
2) Update `.circleci/config.yml`'s `test` job to point to the new Xcode release.
3) Push the branch and wait for the test job to fail
4) Observe which tests failed, and update the relevant `spec/fixtures` to reference
   the values in the `software-versions.json` artifact.
5) Update the fixtures, or rebuild the image if the change is undesired (e.g unintentionally removing simulators or core tools)
6) The documentation will automatically be released to https://circle-macos-docs.s3.amazonaws.com/image-manifest/build-{image-number}/index.html, you then need to PR [circleci-docs](https://circleci.com/docs/2.0/testing-ios/#supported-xcode-versions) with a link to the new documentation and Xcode.
