// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:berga_trans_dash_native/src/hook/native_artifact_fetcher.dart';
import 'package:berga_trans_dash_native/src/hook/native_artifact_manifest.dart';
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

const _assetName = 'berga_trans_dash_native.dart';
const _manifestDefine = 'berga_trans_dash_native_artifact_manifest';
const _requiredNativeAbiVersion = 2;

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final code = input.config.code;
    if (code.targetOS != OS.android && code.targetOS != OS.iOS) return;
    if (code.targetArchitecture != Architecture.arm64) {
      throw UnsupportedError(
        'berga_trans_dash_native supports ARM64 only.',
      );
    }
    if (code.targetOS == OS.iOS && code.iOS.targetSdk != IOSSdk.iPhoneOS) {
      throw UnsupportedError(
        'berga_trans_dash_native supports iOS Device ARM64 only; '
        'iOS Simulator is not supported.',
      );
    }
    if (code.linkModePreference == LinkModePreference.static) {
      throw UnsupportedError(
        'berga_trans_dash_native requires bundled dynamic loading.',
      );
    }

    final configuredManifest = input.userDefines.path(_manifestDefine);
    final manifestUri = configuredManifest ??
        input.packageRoot.resolve('native_artifacts.json');
    final manifestFile = File.fromUri(manifestUri);
    if (!await manifestFile.exists()) {
      throw StateError(
        'BergaTransDash Native Artifact Manifest was not found at '
        '${manifestFile.path}. Provide $_manifestDefine only for a local '
        'verified build.',
      );
    }
    output.dependencies.add(manifestUri);
    final manifest = NativeArtifactManifest.parse(
      await manifestFile.readAsString(),
    );
    final environment = code.targetOS == OS.iOS ? 'iphoneos' : 'android';
    final artifact = manifest.select(
      os: code.targetOS.toString(),
      architecture: code.targetArchitecture.toString(),
      environment: environment,
      requiredNativeAbiVersion: _requiredNativeAbiVersion,
    );
    final cacheUri = input.outputDirectoryShared.resolve(
      'berga_trans_dash_native/${manifest.buildIdentitySha256}/'
      '${artifact.sha256}/${artifact.fileName}',
    );
    final cachedArtifact = await ensureNativeArtifact(
      artifact: artifact,
      destination: File.fromUri(cacheUri),
    );
    final bundledFileName = code.targetOS == OS.iOS
        ? 'libberga_trans_dash_native.dylib'
        : 'libberga_trans_dash.so';
    final bundledUri = input.outputDirectoryShared.resolve(
      'berga_trans_dash_native/bundled/${code.targetOS}/'
      '${code.targetArchitecture}/$environment/$bundledFileName',
    );
    await ensureBundledNativeArtifact(
      cachedArtifact: cachedArtifact,
      destination: File.fromUri(bundledUri),
      artifact: artifact,
    );

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: _assetName,
        file: bundledUri,
        linkMode: DynamicLoadingBundled(),
      ),
    );
  });
}
