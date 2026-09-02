// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

final class NativeArtifactDownloadSource {
  NativeArtifactDownloadSource({
    required this.url,
    required Set<String> allowedRedirectHosts,
  }) : allowedRedirectHosts = Set.unmodifiable(
         allowedRedirectHosts.map((host) => host.toLowerCase()),
       );

  factory NativeArtifactDownloadSource.fromJson(Map<String, Object?> json) =>
      NativeArtifactDownloadSource(
        url: Uri.parse(json['url']! as String),
        allowedRedirectHosts: (json['allowedRedirectHosts']! as List<Object?>)
            .cast<String>()
            .toSet(),
      );

  final Uri url;
  final Set<String> allowedRedirectHosts;
}

final class NativeCorrespondingSource {
  NativeCorrespondingSource({
    required this.id,
    required this.fileName,
    required this.url,
    required this.size,
    required this.sha256,
    required this.license,
  });

  factory NativeCorrespondingSource.fromJson(Map<String, Object?> json) =>
      NativeCorrespondingSource(
        id: json['id']! as String,
        fileName: json['fileName']! as String,
        url: Uri.parse(json['url']! as String),
        size: json['size']! as int,
        sha256: json['sha256']! as String,
        license: json['license']! as String,
      );

  final String id;
  final String fileName;
  final Uri url;
  final int size;
  final String sha256;
  final String license;
}

final class NativeArtifact {
  NativeArtifact({
    this.artifactId = '',
    this.buildId = '',
    required this.os,
    required this.architecture,
    required this.environment,
    required this.fileName,
    required List<NativeArtifactDownloadSource> downloadSources,
    required List<String> correspondingSourceIds,
    required this.size,
    required this.sha256,
  }) : downloadSources = List.unmodifiable(downloadSources),
       correspondingSourceIds = List.unmodifiable(correspondingSourceIds);

  factory NativeArtifact.fromJson(Map<String, Object?> json) => NativeArtifact(
    artifactId: json['artifactId']! as String,
    buildId: json['buildId']! as String,
    os: json['os']! as String,
    architecture: json['architecture']! as String,
    environment: json['environment']! as String,
    fileName: json['fileName']! as String,
    downloadSources: (json['downloadSources']! as List<Object?>)
        .map((value) => NativeArtifactDownloadSource.fromJson(
              (value! as Map).cast<String, Object?>(),
            ))
        .toList(growable: false),
    correspondingSourceIds:
        (json['correspondingSourceIds']! as List<Object?>).cast<String>(),
    size: json['size']! as int,
    sha256: json['sha256']! as String,
  );

  final String artifactId;
  final String buildId;
  final String os;
  final String architecture;
  final String environment;
  final String fileName;
  final List<NativeArtifactDownloadSource> downloadSources;
  final List<String> correspondingSourceIds;
  final int size;
  final String sha256;
}

final class NativeArtifactManifest {
  const NativeArtifactManifest({
    required this.schemaVersion,
    required this.release,
    required this.nativeAbiVersion,
    required this.buildIdentitySha256,
    required this.correspondingSources,
    required this.artifacts,
  });

  factory NativeArtifactManifest.parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Native artifact manifest must be an object');
    }
    final json = decoded.cast<String, Object?>();
    if (json['schemaVersion'] != 2) {
      throw const FormatException('Unsupported native artifact manifest');
    }
    final release = json['release']! as String;
    final nativeAbiVersion = json['nativeAbiVersion']! as int;
    final buildIdentitySha256 = json['buildIdentitySha256']! as String;
    if (!_metadataPattern.hasMatch(release) ||
        nativeAbiVersion != 2 ||
        !_sha256Pattern.hasMatch(buildIdentitySha256)) {
      throw const FormatException('Invalid native artifact release metadata');
    }

    final correspondingSources = (json['correspondingSources']! as List<Object?>)
        .map((value) => NativeCorrespondingSource.fromJson(
              (value! as Map).cast<String, Object?>(),
            ))
        .toList(growable: false);
    if (correspondingSources.length != 1) {
      throw const FormatException(
        'Native ABI 2 requires one MPL corresponding-source archive',
      );
    }
    final sourceIds = <String>{};
    for (final entry in correspondingSources) {
      _validateCorrespondingSource(entry);
      if (!sourceIds.add(entry.id)) {
        throw FormatException('Duplicate corresponding-source ID: ${entry.id}');
      }
    }

    final artifacts = (json['artifacts']! as List<Object?>)
        .map((value) => NativeArtifact.fromJson(
              (value! as Map).cast<String, Object?>(),
            ))
        .toList(growable: false);
    if (artifacts.length != _supportedTargets.length) {
      throw const FormatException(
        'Native ABI 2 requires exactly two translation artifacts',
      );
    }
    final targets = <String>{};
    for (final artifact in artifacts) {
      _validateArtifact(artifact);
      if (artifact.correspondingSourceIds.length != sourceIds.length ||
          !artifact.correspondingSourceIds.toSet().containsAll(sourceIds)) {
        throw FormatException(
          'Artifact ${artifact.artifactId} does not reference the MPL source',
        );
      }
      final target = _targetKey(
        artifact.os,
        artifact.architecture,
        artifact.environment,
      );
      if (!targets.add(target)) {
        throw FormatException('Duplicate native artifact target: $target');
      }
    }
    if (targets.length != _supportedTargets.length ||
        !targets.containsAll(_supportedTargets.keys)) {
      throw const FormatException(
        'Native artifact manifest must contain Android and iOS ARM64 targets',
      );
    }
    return NativeArtifactManifest(
      schemaVersion: 2,
      release: release,
      nativeAbiVersion: nativeAbiVersion,
      buildIdentitySha256: buildIdentitySha256,
      correspondingSources: List.unmodifiable(correspondingSources),
      artifacts: List.unmodifiable(artifacts),
    );
  }

  final int schemaVersion;
  final String release;
  final int nativeAbiVersion;
  final String buildIdentitySha256;
  final List<NativeCorrespondingSource> correspondingSources;
  final List<NativeArtifact> artifacts;

  NativeArtifact select({
    required String os,
    required String architecture,
    required String environment,
    int? requiredNativeAbiVersion,
  }) {
    if (requiredNativeAbiVersion != null &&
        nativeAbiVersion != requiredNativeAbiVersion) {
      throw UnsupportedError(
        'berga_trans_dash_native requires ABI $requiredNativeAbiVersion, '
        'but release $release provides ABI $nativeAbiVersion.',
      );
    }
    final matches = artifacts.where(
      (artifact) =>
          artifact.os == os &&
          artifact.architecture == architecture &&
          artifact.environment == environment,
    );
    if (matches.length != 1) {
      throw UnsupportedError(
        'No translation artifact for $os/$architecture/$environment. '
        'Release: $release.',
      );
    }
    return matches.single;
  }
}

final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
final _metadataPattern = RegExp(r'^[A-Za-z0-9._-]+$');
final _buildIdPattern = RegExp(r'^[A-Fa-f0-9-]{20,64}$');

const _supportedTargets = <String, String>{
  'android/arm64/android': 'libberga_trans_dash-android-arm64.so',
  'ios/arm64/iphoneos': 'libberga_trans_dash-ios-device-arm64.dylib',
};

String _targetKey(String os, String architecture, String environment) =>
    '$os/$architecture/$environment';

void _validateArtifact(NativeArtifact artifact) {
  final target = _targetKey(
    artifact.os,
    artifact.architecture,
    artifact.environment,
  );
  if (!_supportedTargets.containsKey(target) ||
      artifact.fileName != _supportedTargets[target] ||
      !_metadataPattern.hasMatch(artifact.artifactId) ||
      !_buildIdPattern.hasMatch(artifact.buildId) ||
      artifact.downloadSources.isEmpty ||
      artifact.correspondingSourceIds.isEmpty ||
      artifact.correspondingSourceIds.toSet().length !=
          artifact.correspondingSourceIds.length ||
      artifact.size < 1 ||
      !_sha256Pattern.hasMatch(artifact.sha256)) {
    throw FormatException('Invalid native artifact: $target');
  }
  final sourceUrls = <String>{};
  for (final source in artifact.downloadSources) {
    if (!sourceUrls.add(source.url.toString()) ||
        !_validDownloadUri(source.url) ||
        source.url.pathSegments.isEmpty ||
        source.url.pathSegments.last != artifact.fileName ||
        source.allowedRedirectHosts.any(
          (host) =>
              host.isEmpty ||
              host.trim() != host ||
              host.contains('/') ||
              host.contains(':'),
        )) {
      throw FormatException('Invalid native artifact source: $target');
    }
  }
}

void _validateCorrespondingSource(NativeCorrespondingSource source) {
  if (!_metadataPattern.hasMatch(source.id) ||
      source.license != 'MPL-2.0' ||
      !source.fileName.endsWith('.tar.gz') ||
      source.fileName.contains('/') ||
      source.fileName.contains(r'\') ||
      !_validDownloadUri(source.url) ||
      source.url.pathSegments.isEmpty ||
      source.url.pathSegments.last != source.fileName ||
      source.size < 1 ||
      !_sha256Pattern.hasMatch(source.sha256)) {
    throw const FormatException('Invalid MPL corresponding-source archive');
  }
}

bool _validDownloadUri(Uri uri) =>
    uri.host.isNotEmpty &&
    uri.userInfo.isEmpty &&
    !uri.hasFragment &&
    (uri.scheme == 'https' || _isLoopbackHttp(uri));

bool _isLoopbackHttp(Uri uri) =>
    uri.scheme == 'http' &&
    (uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '::1');
