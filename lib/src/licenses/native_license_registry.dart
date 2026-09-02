// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

var _registered = false;

/// Registers native dependency notices with Flutter's standard license page.
void registerNativeLicenses({AssetBundle? assetBundle}) {
  final bundle = assetBundle ?? rootBundle;
  if (_registered) return;
  _registered = true;
  _registerAssets(_licenseAssets, bundle);
}

void _registerAssets(
  List<({List<String> components, String path})> assets,
  AssetBundle bundle,
) {
  LicenseRegistry.addLicense(() async* {
    for (final asset in assets) {
      final data = await bundle.load(
        'packages/berga_trans_dash_native/${asset.path}',
      );
      final text = utf8.decode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      yield LicenseEntryWithLineBreaks(asset.components, text);
    }
  });
}

const _licenseAssets = <({List<String> components, String path})>[
  (
    components: ['berga_trans_dash_native third-party notices'],
    path: 'assets/native_notices/COMMON_NOTICES.txt',
  ),
  (
    components: ['Mozilla Translations', 'Bergamot inference'],
    path: 'THIRD_PARTY_LICENSES/Mozilla-Translations-MPL-2.0.txt',
  ),
  (components: ['Marian NMT'], path: 'THIRD_PARTY_LICENSES/Marian-MIT.txt'),
  (components: ['ssplit-cpp'], path: 'THIRD_PARTY_LICENSES/ssplit-cpp.txt'),
  (components: ['PCRE2 10.47'], path: 'THIRD_PARTY_LICENSES/PCRE2-BSD-3-Clause.txt'),
  (
    components: ['SLJIT bundled by PCRE2 10.47'],
    path: 'THIRD_PARTY_LICENSES/PCRE2-SLJIT-BSD-2-Clause.txt',
  ),
  (
    components: ['SentencePiece'],
    path: 'THIRD_PARTY_LICENSES/SentencePiece-Apache-2.0.txt',
  ),
  (components: ['ruy'], path: 'THIRD_PARTY_LICENSES/ruy-Apache-2.0.txt'),
  (components: ['Abseil'], path: 'THIRD_PARTY_LICENSES/Abseil-Apache-2.0.txt'),
  (components: ['esaxx'], path: 'THIRD_PARTY_LICENSES/esaxx-MIT.txt'),
  (
    components: ['Darts-clone'],
    path: 'THIRD_PARTY_LICENSES/Darts-clone-BSD-3-Clause.txt',
  ),
  (
    components: ['protobuf-lite'],
    path: 'THIRD_PARTY_LICENSES/protobuf-lite-BSD-3-Clause.txt',
  ),
  (components: ['cpuinfo'], path: 'THIRD_PARTY_LICENSES/cpuinfo-BSD-2-Clause.txt'),
  (components: ['clog'], path: 'THIRD_PARTY_LICENSES/clog-BSD-2-Clause.txt'),
  (components: ['intgemm'], path: 'THIRD_PARTY_LICENSES/intgemm-MIT.txt'),
  (components: ['simd_utils'], path: 'THIRD_PARTY_LICENSES/simd_utils-BSD-2-Clause.txt'),
  (components: ['FBGEMM'], path: 'THIRD_PARTY_LICENSES/FBGEMM-BSD-3-Clause.txt'),
  (components: ['Faiss'], path: 'THIRD_PARTY_LICENSES/Faiss-MIT.txt'),
  (components: ['yaml-cpp'], path: 'THIRD_PARTY_LICENSES/yaml-cpp-MIT.txt'),
  (
    components: ['Pathie-cpp'],
    path: 'THIRD_PARTY_LICENSES/Pathie-cpp-BSD-2-Clause.txt',
  ),
  (components: ['spdlog'], path: 'THIRD_PARTY_LICENSES/spdlog-MIT.txt'),
  (components: ['zlib'], path: 'THIRD_PARTY_LICENSES/zlib.txt'),
  (components: ['CLI11'], path: 'THIRD_PARTY_LICENSES/CLI11-BSD-3-Clause.txt'),
  (components: ['cnpy'], path: 'THIRD_PARTY_LICENSES/cnpy-MIT.txt'),
  (components: ['mio'], path: 'THIRD_PARTY_LICENSES/mio-MIT.txt'),
  (components: ['phf'], path: 'THIRD_PARTY_LICENSES/phf-MIT.txt'),
  (components: ['zstr'], path: 'THIRD_PARTY_LICENSES/zstr-MIT.txt'),
  (
    components: ['half_float umHalf'],
    path: 'THIRD_PARTY_LICENSES/half-float-umHalf-BSD-3-Clause.txt',
  ),
  (
    components: ['half_float umHalf implementation'],
    path: 'THIRD_PARTY_LICENSES/half-float-umHalf-inl-BSD-3-Clause.txt',
  ),
  (
    components: ['half_float Visual Studio stdint'],
    path: 'THIRD_PARTY_LICENSES/half-float-stdint-BSD-3-Clause.txt',
  ),
  (components: ['sse2neon'], path: 'THIRD_PARTY_LICENSES/sse2neon-MIT.txt'),
  (
    components: ['AVX math functions'],
    path: 'THIRD_PARTY_LICENSES/simd-avx-math-Zlib.txt',
  ),
  (
    components: ['NEON math functions'],
    path: 'THIRD_PARTY_LICENSES/simd-neon-math-Zlib.txt',
  ),
  (
    components: ['SSE math functions'],
    path: 'THIRD_PARTY_LICENSES/simd-sse-math-Zlib.txt',
  ),
  (
    components: ['fmt bundled by spdlog (legacy tree)'],
    path: 'THIRD_PARTY_LICENSES/fmt-BSD-2-Clause.txt',
  ),
  (
    components: ['fmt bundled by spdlog (include tree)'],
    path: 'THIRD_PARTY_LICENSES/fmt-include-BSD-2-Clause.txt',
  ),
  (
    components: ['Dmitry Vyukov bounded MPMC queue'],
    path: 'THIRD_PARTY_LICENSES/bounded-mpmc-queue-BSD-2-Clause.txt',
  ),
  (
    components: ['Marian thread pool'],
    path: 'THIRD_PARTY_LICENSES/Marian-thread-pool-Zlib.txt',
  ),
  (
    components: ['Microsoft CNTK ExceptionWithCallStack'],
    path: 'THIRD_PARTY_LICENSES/Microsoft-CNTK-MIT.txt',
  ),
  (components: ['ONNX protobuf schema'], path: 'THIRD_PARTY_LICENSES/ONNX-MIT.txt'),
  (
    components: ['AsmJit bundled by FBGEMM'],
    path: 'THIRD_PARTY_LICENSES/AsmJit-Zlib.txt',
  ),
  (
    components: ['cpuinfo bundled by FBGEMM'],
    path: 'THIRD_PARTY_LICENSES/FBGEMM-cpuinfo-BSD-2-Clause.txt',
  ),
  (
    components: ['GoogleTest bundled by FBGEMM and ruy'],
    path: 'THIRD_PARTY_LICENSES/GoogleTest-BSD-3-Clause.txt',
  ),
  (
    components: ['GoogleMock generator'],
    path: 'THIRD_PARTY_LICENSES/GoogleMock-generator-Apache-2.0.txt',
  ),
  (
    components: ['PCRE2 CMake scripts'],
    path: 'THIRD_PARTY_LICENSES/PCRE2-CMake-BSD-3-Clause.txt',
  ),
];
