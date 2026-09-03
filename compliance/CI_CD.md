<!-- SPDX-License-Identifier: MPL-2.0 -->

# CI and candidate staging

The `CI` workflow runs on pull requests and pushes to `main`. It uses Flutter
3.41.0 and performs dependency resolution, static analysis, the full test suite
including the public-boundary checks, and `dart pub publish --dry-run`.

The manually dispatched `Stage package candidate` workflow repeats those gates
and creates a deterministic source review archive plus its SHA-256 file. It
uploads only a private GitHub Actions artifact with 14-day retention. It does
not create a tag, GitHub Release, production Artifact Manifest, or pub.dev
publication.

Production Native assets are an explicit release operation, not a CI side
effect. The `native-v0.1.0-rc.1` GitHub pre-release contains the checked-in
Manifest, both supported ARM64 binaries, and their MPL corresponding-source
archive. Consumers use the immutable Git tag; pub.dev publication remains
disabled.

All third-party actions are pinned to complete commit SHAs. Both workflows use
read-only repository permissions and do not require repository secrets.
