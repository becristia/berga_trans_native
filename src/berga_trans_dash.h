// SPDX-License-Identifier: MPL-2.0

#ifndef BERGA_TRANS_DASH_H_
#define BERGA_TRANS_DASH_H_

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#define OT_EXPORT __declspec(dllexport)
#else
#define OT_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define OT_ABI_VERSION 2u

#define OT_MAX_TRANSLATION_INPUT_BYTES (64u * 1024u)
#define OT_MAX_TRANSLATION_BATCH_COUNT 128u
#define OT_MAX_TRANSLATION_BATCH_BYTES (512u * 1024u)
#define OT_MAX_RUNTIME_RESOURCE_BYTES (64u * 1024u)
#define OT_MAX_TRANSLATION_OUTPUT_BYTES (512u * 1024u)
#define OT_MAX_TRANSLATION_TOTAL_OUTPUT_BYTES (4u * 1024u * 1024u)

typedef struct ot_engine ot_engine;
typedef struct ot_model ot_model;

typedef enum ot_error_code {
  OT_OK = 0,
  OT_ERROR_INVALID_ARGUMENT = 1,
  OT_ERROR_ENGINE_CREATE = 2,
  OT_ERROR_MODEL_LOAD = 3,
  OT_ERROR_MODEL_INCOMPATIBLE = 4,
  OT_ERROR_TRANSLATION = 5,
  OT_ERROR_OUT_OF_MEMORY = 6,
  OT_ERROR_INTERNAL = 7,
  OT_ERROR_INPUT_TOO_LARGE = 8,
  OT_ERROR_OUTPUT_TOO_LARGE = 9,
  OT_ERROR_INVALID_UTF8 = 10
} ot_error_code;

typedef struct ot_string_view {
  const char* data;
  size_t length;
} ot_string_view;

typedef struct ot_owned_string {
  char* data;
  size_t length;
} ot_owned_string;

typedef struct ot_engine_config {
  uint32_t worker_threads;
  uint32_t cache_size;
  uint8_t enable_debug_logs;
} ot_engine_config;

typedef struct ot_model_descriptor {
  ot_string_view package_id;
  ot_string_view source_language;
  ot_string_view target_language;
  ot_string_view runtime_profile;
  ot_string_view model_path;
  ot_string_view shortlist_path;
  ot_string_view shared_vocabulary_path;
  ot_string_view source_vocabulary_path;
  ot_string_view target_vocabulary_path;
} ot_model_descriptor;

typedef struct ot_string_list_result {
  ot_owned_string* items;
  size_t count;
} ot_string_list_result;

/*
 * ABI ownership and concurrency contract:
 *
 * - ot_string_view values and descriptor arrays are borrowed only for the
 *   duration of the call. The caller retains ownership of their memory.
 * - Handles returned through output parameters belong to the caller and must
 *   be released exactly once with the matching destroy/unload function.
 * - Result buffers returned on success belong to the caller and must be
 *   released exactly once with the matching *_result_free function. The free
 *   functions also accept cleared or zero-initialized result structs.
 * - Handles are not internally synchronized. Calls using the same handle,
 *   including destruction, must be serialized by the caller.
 * - ot_last_error_message returns thread-local storage that remains valid only
 *   until the next BergaTransDash ABI call on the same thread. Copy it before
 *   making another call. The returned pointer must not be freed.
 */

OT_EXPORT uint32_t ot_abi_version(void);
/* Returned Artifact identity is immutable and valid for the process lifetime. */
OT_EXPORT ot_error_code ot_native_artifact_id(ot_string_view* output);
/* Returned compliance resource views are immutable process-lifetime data. */
OT_EXPORT ot_error_code ot_runtime_resource_get(
    const ot_string_view* name,
    ot_string_view* output);
OT_EXPORT const char* ot_last_error_message(size_t* length);

OT_EXPORT ot_error_code ot_engine_create(
    const ot_engine_config* config,
    ot_engine** output);
OT_EXPORT void ot_engine_destroy(ot_engine* engine);

OT_EXPORT ot_error_code ot_model_load(
    ot_engine* engine,
    const ot_model_descriptor* descriptor,
    ot_model** output);
OT_EXPORT void ot_model_unload(ot_model* model);

OT_EXPORT ot_error_code ot_translate_batch(
    ot_engine* engine,
    ot_model* model,
    const ot_string_view* inputs,
    size_t input_count,
    ot_string_list_result* output);
OT_EXPORT void ot_string_list_result_free(ot_string_list_result* result);

#ifdef __cplusplus
}
#endif

#endif  // BERGA_TRANS_DASH_H_
