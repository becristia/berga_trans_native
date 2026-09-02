// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';

import 'package:berga_trans_dash_native/src/hook/native_artifact_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('checked-in RC2 Manifest matches the public release contract', () {
    final file = File('native_artifacts.json');
    expect(file.existsSync(), isTrue);

    final manifest = NativeArtifactManifest.parse(file.readAsStringSync());
    expect(manifest.release, 'native-v0.1.0-rc.2');
    expect(manifest.nativeAbiVersion, 2);
    expect(manifest.artifacts, hasLength(2));
    expect(manifest.correspondingSources, hasLength(1));

    final releaseBase =
        'https://github.com/becristia/berga_trans_native/releases/download/'
        'native-v0.1.0-rc.2/';
    final source = manifest.correspondingSources.single;
    expect(source.url.toString(), '$releaseBase${source.fileName}');
    for (final artifact in manifest.artifacts) {
      final download = artifact.downloadSources.single;
      expect(download.url.toString(), '$releaseBase${artifact.fileName}');
      expect(
        download.allowedRedirectHosts,
        {'release-assets.githubusercontent.com'},
      );
    }
  });

  test('parses the fixed ABI 2 Android and iOS matrix', () {
    final manifest = NativeArtifactManifest.parse(jsonEncode(_manifest()));

    expect(manifest.schemaVersion, 2);
    expect(manifest.nativeAbiVersion, 2);
    expect(manifest.artifacts, hasLength(2));
    expect(manifest.correspondingSources.single.license, 'MPL-2.0');
    expect(
      manifest
          .select(
            os: 'android',
            architecture: 'arm64',
            environment: 'android',
            requiredNativeAbiVersion: 2,
          )
          .fileName,
      'libberga_trans_dash-android-arm64.so',
    );
    expect(
      manifest
          .select(
            os: 'ios',
            architecture: 'arm64',
            environment: 'iphoneos',
          )
          .fileName,
      'libberga_trans_dash-ios-device-arm64.dylib',
    );
  });

  test('rejects schema 1 and any ABI other than 2', () {
    expect(
      () => _parseChanged((json) => json['schemaVersion'] = 1),
      throwsFormatException,
    );
    expect(
      () => _parseChanged((json) => json['nativeAbiVersion'] = 1),
      throwsFormatException,
    );
  });

  test('rejects a missing or third artifact', () {
    expect(
      () => _parseChanged(
        (json) => (json['artifacts']! as List<Object?>).removeLast(),
      ),
      throwsFormatException,
    );
    expect(
      () => _parseChanged((json) {
        final artifacts = json['artifacts']! as List<Object?>;
        artifacts.add(_deepCopy(artifacts.first!));
      }),
      throwsFormatException,
    );
  });

  test('rejects an unsupported target and filename', () {
    expect(
      () => _parseChanged((json) {
        final artifact = (json['artifacts']! as List<Object?>).first! as Map;
        artifact['architecture'] = 'x64';
      }),
      throwsFormatException,
    );
    expect(
      () => _parseChanged((json) {
        final artifact = (json['artifacts']! as List<Object?>).last! as Map;
        artifact['environment'] = 'iphonesimulator';
      }),
      throwsFormatException,
    );
    expect(
      () => _parseChanged((json) {
        final artifact = (json['artifacts']! as List<Object?>).first! as Map;
        artifact['fileName'] = 'unexpected.so';
      }),
      throwsFormatException,
    );
  });

  test('rejects bad hashes and missing MPL source references', () {
    expect(
      () => _parseChanged((json) {
        final artifact = (json['artifacts']! as List<Object?>).first! as Map;
        artifact['sha256'] = 'not-a-sha256';
      }),
      throwsFormatException,
    );
    expect(
      () => _parseChanged((json) {
        final artifact = (json['artifacts']! as List<Object?>).first! as Map;
        artifact['correspondingSourceIds'] = <Object?>[];
      }),
      throwsFormatException,
    );
    expect(
      () => _parseChanged((json) {
        final source =
            (json['correspondingSources']! as List<Object?>).single! as Map;
        source['license'] = 'Proprietary';
      }),
      throwsFormatException,
    );
  });

  test('rejects non-HTTPS remote sources', () {
    expect(
      () => _parseChanged((json) {
        final artifact = (json['artifacts']! as List<Object?>).first! as Map;
        final source =
            (artifact['downloadSources']! as List<Object?>).single! as Map;
        source['url'] =
            'http://downloads.example.com/libberga_trans_dash-android-arm64.so';
      }),
      throwsFormatException,
    );
  });

  test('selection fails closed for unsupported targets and ABI', () {
    final manifest = NativeArtifactManifest.parse(jsonEncode(_manifest()));
    expect(
      () => manifest.select(
        os: 'ios',
        architecture: 'arm64',
        environment: 'iphonesimulator',
      ),
      throwsUnsupportedError,
    );
    expect(
      () => manifest.select(
        os: 'android',
        architecture: 'arm64',
        environment: 'android',
        requiredNativeAbiVersion: 1,
      ),
      throwsUnsupportedError,
    );
  });
}

NativeArtifactManifest _parseChanged(
  void Function(Map<String, Object?> json) change,
) {
  final json = _manifest();
  change(json);
  return NativeArtifactManifest.parse(jsonEncode(json));
}

Map<String, Object?> _manifest() => {
  'schemaVersion': 2,
  'release': 'native-v0.1.0-rc.2-test',
  'nativeAbiVersion': 2,
  'buildIdentitySha256': List.filled(64, 'a').join(),
  'correspondingSources': [
    {
      'id': 'bergamot-mpl-source',
      'fileName': 'berga-trans-dash-native-abi2-mpl-source.tar.gz',
      'url':
          'https://downloads.example.com/berga-trans-dash-native-abi2-mpl-source.tar.gz',
      'size': 1234,
      'sha256': List.filled(64, 'b').join(),
      'license': 'MPL-2.0',
    },
  ],
  'artifacts': [
    _artifact(
      artifactId: 'android-arm64',
      os: 'android',
      environment: 'android',
      fileName: 'libberga_trans_dash-android-arm64.so',
      sha256: List.filled(64, 'c').join(),
    ),
    _artifact(
      artifactId: 'ios-device-arm64',
      os: 'ios',
      environment: 'iphoneos',
      fileName: 'libberga_trans_dash-ios-device-arm64.dylib',
      sha256: List.filled(64, 'd').join(),
    ),
  ],
};

Map<String, Object?> _artifact({
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
    {
      'url': 'https://downloads.example.com/$fileName',
      'allowedRedirectHosts': <String>[],
    },
  ],
  'correspondingSourceIds': ['bergamot-mpl-source'],
  'size': 42,
  'sha256': sha256,
};

Object? _deepCopy(Object value) => jsonDecode(jsonEncode(value));
