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

All third-party actions are pinned to complete commit SHAs. Both workflows use
read-only repository permissions and do not require repository secrets.
