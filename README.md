# BergaTransDash Native

`berga_trans_dash_native` is the public MPL-2.0 Native Assets loader and
compliance boundary for the proprietary BergaTransDash translation package.

It contains artifact selection and verification, license registration, the
stable translation-only C ABI header, and MPL corresponding-source material.
It contains no product API, model manager, Dart FFI bindings, language
identification, or first-party native implementation.

## Pre-release status

Native ABI 2 has not been published. The package intentionally sets
`publish_to: none` and does not include a production `native_artifacts.json`.
Tests inject a local schema-2 manifest through
`berga_trans_dash_native_artifact_manifest`.

Supported release targets are Android ARM64 and iOS Device ARM64. iOS
Simulator is rejected.
