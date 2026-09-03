# Changelog

## Next - Unreleased

## 0.1.0-rc.1 - 2026-09-02

- Publish the production ABI 2 Artifact Manifest and GitHub pre-release assets
  for Android ARM64 and iOS Device ARM64.
- Add pinned continuous integration and a manual, non-publishing package
  candidate staging workflow.
- Isolate concurrent Native Artifact downloads in per-invocation temporary
  directories and avoid retrying integrity or redirect-trust failures.
- Namespace the shared artifact cache by the verified Native build identity.
- Make public patch provenance and third-party notice references independently
  verifiable without the private SDK repository.

## 0.1.0-dev.1

- Split the public Native Assets loader from the proprietary translation SDK.
- Define translation-only Native ABI 2.
- Remove Lingua, CLD2, fastText, LID profiles, and LID backend selection.
