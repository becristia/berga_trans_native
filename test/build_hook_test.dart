// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';

import 'package:berga_trans_dash_native/berga_trans_dash_native.dart';
import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks/hooks.dart';

import '../hook/build.dart' as build_hook;

void main() {
  test('Build Hook selects the Android ARM64 ABI 2 artifact', () async {
    final fixture = await _HookFixture.create();
    addTearDown(fixture.dispose);

    await fixture.runAndroid();
  });

  test('Build Hook selects the iOS Device ARM64 ABI 2 artifact', () async {
    final fixture = await _HookFixture.create();
    addTearDown(fixture.dispose);

    await fixture.runIOSDevice();
  });

  test('Build Hook rejects iOS Simulator and non-ARM64 targets', () async {
    final fixture = await _HookFixture.create();
    addTearDown(fixture.dispose);

    await expectLater(fixture.runIOSSimulator(), throwsUnsupportedError);
    await expectLater(fixture.runAndroidX64(), throwsUnsupportedError);
  });

  test('Build Hook reports a missing configured Artifact Manifest', () async {
    final missingManifest = Directory.systemTemp.uri
        .resolve(
          'berga_trans_dash_native_missing_'
          '${DateTime.now().microsecondsSinceEpoch}.json',
        )
        .toFilePath();
    await expectLater(
      testCodeBuildHook(
        mainMethod: build_hook.main,
        targetOS: OS.android,
        targetArchitecture: Architecture.arm64,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {
              'berga_trans_dash_native_artifact_manifest': missingManifest,
            },
            basePath: Directory.current.uri,
          ),
        ),
        check: (_, _) {},
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Artifact Manifest was not found'),
        ),
      ),
    );
  });

  test('Build Hook rejects an artifact with the wrong hash', () async {
    final fixture = await _HookFixture.create(useWrongHash: true);
    addTearDown(fixture.dispose);

    await expectLater(fixture.runAndroid(), throwsStateError);
  });
}

final class _HookFixture {
  _HookFixture(this.root, this.server, this.manifest);

  static const bytes = <int>[1, 4, 9, 16];

  final Directory root;
  final HttpServer server;
  final File manifest;

  static Future<_HookFixture> create({bool useWrongHash = false}) async {
    final root = await Directory.systemTemp.createTemp('native_hook_test_');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.statusCode = HttpStatus.ok;
      request.response.add(bytes);
      await request.response.close();
    });
    final baseUrl = 'http://${server.address.address}:${server.port}';
    final digest = useWrongHash
        ? List.filled(64, '0').join()
        : sha256.convert(bytes).toString();
    final manifest = File('${root.path}/native_artifacts.json');
    await manifest.writeAsString(
      jsonEncode({
        'schemaVersion': 2,
        'release': 'native-v0.1.0-rc.2-test',
        'nativeAbiVersion': 2,
        'buildIdentitySha256': List.filled(64, 'a').join(),
        'correspondingSources': [
          {
            'id': 'bergamot-mpl-source',
            'fileName': 'berga-trans-dash-native-abi2-mpl-source.tar.gz',
            'url':
                '$baseUrl/berga-trans-dash-native-abi2-mpl-source.tar.gz',
            'size': 1,
            'sha256': List.filled(64, 'b').join(),
            'license': 'MPL-2.0',
          },
        ],
        'artifacts': [
          _artifact(
            baseUrl: baseUrl,
            artifactId: 'android-arm64',
            os: 'android',
            environment: 'android',
            fileName: 'libberga_trans_dash-android-arm64.so',
            sha256: digest,
          ),
          _artifact(
            baseUrl: baseUrl,
            artifactId: 'ios-device-arm64',
            os: 'ios',
            environment: 'iphoneos',
            fileName: 'libberga_trans_dash-ios-device-arm64.dylib',
            sha256: digest,
          ),
        ],
      }),
    );
    return _HookFixture(root, server, manifest);
  }

  static Map<String, Object?> _artifact({
    required String baseUrl,
    required String artifactId,
    required String os,
    required String environment,
    required String fileName,
    required String sha256,
  }) => {
    'artifactId': artifactId,
    'buildId': '1234567890abcdef1234567890abcdef12345678',
    'os': os,
    'architecture': 'arm64',
    'environment': environment,
    'fileName': fileName,
    'downloadSources': [
      {'url': '$baseUrl/$fileName', 'allowedRedirectHosts': <String>[]},
    ],
    'correspondingSourceIds': ['bergamot-mpl-source'],
    'size': bytes.length,
    'sha256': sha256,
  };

  PackageUserDefines get userDefines => PackageUserDefines(
    workspacePubspec: PackageUserDefinesSource(
      defines: {
        'berga_trans_dash_native_artifact_manifest': manifest.path,
      },
      basePath: root.uri,
    ),
  );

  Future<void> runAndroid() => testCodeBuildHook(
    mainMethod: build_hook.main,
    targetOS: OS.android,
    targetArchitecture: Architecture.arm64,
    userDefines: userDefines,
    check: (input, output) async {
      final asset = output.assets.code.single;
      expect(asset.id, bergaTransDashNativeAssetId);
      expect(asset.file!.pathSegments.last, 'libberga_trans_dash.so');
      expect(await File.fromUri(asset.file!).readAsBytes(), bytes);
      final cachedArtifact = File.fromUri(
        input.outputDirectoryShared.resolve(
          'berga_trans_dash_native/${sha256.convert(bytes)}/'
          'libberga_trans_dash-android-arm64.so',
        ),
      );
      expect(await cachedArtifact.readAsBytes(), bytes);
    },
  );

  Future<void> runIOSDevice() => testCodeBuildHook(
    mainMethod: build_hook.main,
    targetOS: OS.iOS,
    targetArchitecture: Architecture.arm64,
    targetIOSSdk: IOSSdk.iPhoneOS,
    userDefines: userDefines,
    check: (_, output) async {
      final asset = output.assets.code.single;
      expect(asset.id, bergaTransDashNativeAssetId);
      expect(
        asset.file!.pathSegments.last,
        'libberga_trans_dash_native.dylib',
      );
      expect(await File.fromUri(asset.file!).readAsBytes(), bytes);
    },
  );

  Future<void> runIOSSimulator() => testCodeBuildHook(
    mainMethod: build_hook.main,
    targetOS: OS.iOS,
    targetArchitecture: Architecture.arm64,
    targetIOSSdk: IOSSdk.iPhoneSimulator,
    userDefines: userDefines,
    check: (_, _) {},
  );

  Future<void> runAndroidX64() => testCodeBuildHook(
    mainMethod: build_hook.main,
    targetOS: OS.android,
    targetArchitecture: Architecture.x64,
    userDefines: userDefines,
    check: (_, _) {},
  );

  Future<void> dispose() async {
    await server.close(force: true);
    if (await root.exists()) await root.delete(recursive: true);
  }
}
