# Native dependency license bundle

This directory contains translation-runtime dependency license and attribution material copied or extracted from the exact prepared source used for Native ABI 2.

| Components | SPDX/license | Bundled text |
|---|---|---|
| Mozilla Translations, Bergamot inference | MPL-2.0 | Mozilla-Translations-MPL-2.0.txt |
| Marian NMT | MIT | Marian-MIT.txt |
| ssplit-cpp | Apache-2.0; LGPL-2.1-only data excluded | ssplit-cpp.txt |
| PCRE2 10.47 | BSD-3-Clause WITH PCRE2-exception | PCRE2-BSD-3-Clause.txt |
| SLJIT bundled by PCRE2 10.47 | BSD-2-Clause | PCRE2-SLJIT-BSD-2-Clause.txt |
| SentencePiece | Apache-2.0 | SentencePiece-Apache-2.0.txt |
| ruy | Apache-2.0 | ruy-Apache-2.0.txt |
| Abseil | Apache-2.0 | Abseil-Apache-2.0.txt |
| esaxx | MIT | esaxx-MIT.txt |
| Darts-clone | BSD-3-Clause | Darts-clone-BSD-3-Clause.txt |
| protobuf-lite | BSD-3-Clause | protobuf-lite-BSD-3-Clause.txt |
| cpuinfo | BSD-2-Clause | cpuinfo-BSD-2-Clause.txt |
| clog | BSD-2-Clause | clog-BSD-2-Clause.txt |
| intgemm | MIT AND BSL-1.0 | intgemm-MIT.txt |
| simd_utils | BSD-2-Clause | simd_utils-BSD-2-Clause.txt |
| Faiss | MIT | Faiss-MIT.txt |
| yaml-cpp | MIT | yaml-cpp-MIT.txt |
| Pathie-cpp | BSD-2-Clause | Pathie-cpp-BSD-2-Clause.txt |
| spdlog | MIT | spdlog-MIT.txt |
| zlib | Zlib | zlib.txt |
| CLI11 | BSD-3-Clause | CLI11-BSD-3-Clause.txt |
| cnpy | MIT | cnpy-MIT.txt |
| mio | MIT | mio-MIT.txt |
| phf | MIT | phf-MIT.txt |
| zstr | MIT | zstr-MIT.txt |
| FBGEMM | BSD-3-Clause | FBGEMM-BSD-3-Clause.txt |
| half_float umHalf | BSD-3-Clause | half-float-umHalf-BSD-3-Clause.txt |
| half_float umHalf implementation | BSD-3-Clause | half-float-umHalf-inl-BSD-3-Clause.txt |
| half_float Visual Studio stdint | BSD-3-Clause | half-float-stdint-BSD-3-Clause.txt |
| sse2neon | MIT | sse2neon-MIT.txt |
| AVX math functions | Zlib | simd-avx-math-Zlib.txt |
| NEON math functions | Zlib | simd-neon-math-Zlib.txt |
| SSE math functions | Zlib | simd-sse-math-Zlib.txt |
| fmt bundled by spdlog (legacy tree) | BSD-2-Clause | fmt-BSD-2-Clause.txt |
| fmt bundled by spdlog (include tree) | BSD-2-Clause | fmt-include-BSD-2-Clause.txt |
| Dmitry Vyukov bounded MPMC queue | BSD-2-Clause AND MIT | bounded-mpmc-queue-BSD-2-Clause.txt |
| Marian thread pool | Zlib | Marian-thread-pool-Zlib.txt |
| Microsoft CNTK ExceptionWithCallStack | MIT | Microsoft-CNTK-MIT.txt |
| ONNX protobuf schema | MIT | ONNX-MIT.txt |
| AsmJit bundled by FBGEMM | Zlib | AsmJit-Zlib.txt |
| cpuinfo bundled by FBGEMM | BSD-2-Clause | FBGEMM-cpuinfo-BSD-2-Clause.txt |
| GoogleTest bundled by FBGEMM and ruy | BSD-3-Clause | GoogleTest-BSD-3-Clause.txt |
| GoogleMock generator | Apache-2.0 | GoogleMock-generator-Apache-2.0.txt |
| PCRE2 CMake scripts | BSD-3-Clause | PCRE2-CMake-BSD-3-Clause.txt |

`ssplit-cpp/nonbreaking_prefixes` is LGPL-2.1-only data. It is not compiled, copied, or distributed by berga_trans_dash.

The ignored `third_party/` reference checkouts are not part of the pub package or native binaries. Their provenance is documented in `THIRD_PARTY_NOTICES` and the native dependency lock.
