# BergaTransDash Native

`berga_trans_dash_native` is the public MPL-2.0 Native Assets loader and
compliance boundary for the proprietary BergaTransDash translation package.

It contains artifact selection and verification, license registration, the
stable translation-only C ABI header, and MPL corresponding-source material.
It contains no product API, model manager, Dart FFI bindings, language
identification, or first-party native implementation.

## RC release

Native ABI 2 is published as the `native-v0.1.0-rc.1` GitHub pre-release. The
checked-in `native_artifacts.json` pins its Android ARM64 and iOS Device ARM64
binaries, MPL-2.0 corresponding source, byte sizes, and SHA-256 digests.

The package is not published to pub.dev and intentionally retains
`publish_to: none`. Consumers must pin the immutable public Git tag:

```yaml
dependencies:
  berga_trans_dash_native:
    git:
      url: https://github.com/becristia/berga_trans_native.git
      ref: native-v0.1.0-rc.1
```

Local verified builds can still override the manifest through
`berga_trans_dash_native_artifact_manifest`.

Supported release targets are Android ARM64 and iOS Device ARM64. iOS
Simulator is rejected.

## Continuous integration

Pull requests and `main` run analysis, tests, the public-boundary gate, and a
package dry-run. Manual candidate staging creates an Actions artifact for
review without publishing it. See [CI and candidate staging](compliance/CI_CD.md).
