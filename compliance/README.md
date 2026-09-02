<!-- SPDX-License-Identifier: MPL-2.0 -->

# Compliance boundary

This repository contains only the public Native Assets loader, the stable
translation-only ABI 2 header, the two MPL patches required by the mobile
translation runtime, and redistributable notices and license texts.

It does not contain the BergaTransDash product engine, Catalog or model
management code, Dart FFI bindings, first-party C++ implementation, internal
build and signing tools, or language-identification components.

The schema 2 Artifact Manifest associates both mobile ARM64 artifacts with one
MPL-2.0 corresponding-source archive. That archive is produced by the private
release tooling from the exact prepared Mozilla/Bergamot source used for the
build. It contains the two public patches, the MPL license, modification notes,
and the source offer. It must not contain first-party implementation code or
private tooling.
