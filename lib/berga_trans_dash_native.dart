// SPDX-License-Identifier: MPL-2.0

library;

import 'package:flutter/services.dart';

import 'src/licenses/native_license_registry.dart';

/// Canonical code-asset identifier produced by this package's Build Hook.
const String bergaTransDashNativeAssetId =
    'package:berga_trans_dash_native/berga_trans_dash_native.dart';

/// Registers licenses for the translation-only native runtime.
void registerBergaTransDashNativeLicenses({AssetBundle? assetBundle}) =>
    registerNativeLicenses(assetBundle: assetBundle);
