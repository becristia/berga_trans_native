# BergaTransDash Native Public Module Rules

## Scope

This directory contains the public MPL-2.0 package
`berga_trans_dash_native`. Its scope is deliberately limited to the
translation-only Flutter Native Assets Build Hook, artifact manifest parsing
and verified downloads, license registration, the stable public C ABI 2
header, MPL compliance patches, public notices, and tests for those boundaries.

It must never contain product API or implementation code such as the Engine,
catalog security, model lifecycle, workers, Dart FFI bindings, first-party C++
implementations, signing tools, release credentials, benchmarks, or internal
architecture documents. It must also never contain language identification:
no Lingua, CLD2, fastText, LID workers, LID ABI symbols, backend selection, or
language-profile selection.

## Licensing

- First-party files in this module use MPL-2.0.
- Third-party license texts and notices retain their original identity.
- Corresponding-source material must be sufficient for the MPL-covered code
  distributed in native binaries, without including proprietary first-party
  implementation source.

## Package Contract

- The package exports the canonical Native Asset ID and license-registration
  helpers from `lib/berga_trans_dash_native.dart`.
- The Build Hook owns the code asset and uses only
  `berga_trans_dash_native_*` user-define names.
- Native artifact manifest schema 2 requires exactly two ABI 2 artifacts
  (Android ARM64 and iOS Device ARM64) and fails closed on extra/missing
  targets, unsupported ABI/target, unsafe URL, size mismatch, or SHA-256
  mismatch.
- RC releases are distributed through immutable Git tags and GitHub
  pre-releases. The checked-in production `native_artifacts.json` must point
  to the matching release assets and remain covered by manifest tests.
- Keep `publish_to: none` until a separate pub.dev publication is deliberately
  configured; Git consumers must pin an immutable release tag.

## Engineering Discipline

- Add only files required by the public loader or compliance boundary.
- Do not run `dart format` or `flutter clean`.
- Do not add Android/iOS MethodChannel plugin implementations.
- Do not modify CI/CD, create releases/tags, or publish the package without
  separate explicit authorization.
- Do not delete files or directories without explicit authorization.

## Validation

Run:

```sh
flutter analyze
flutter test
dart pub publish --dry-run
```

Also run the public-boundary allowlist check and confirm the package contains no
proprietary paths or implementation symbols.
