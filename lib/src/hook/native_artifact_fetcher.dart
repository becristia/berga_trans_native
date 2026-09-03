// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'native_artifact_manifest.dart';

Future<File> ensureNativeArtifact({
  required NativeArtifact artifact,
  required File destination,
  HttpClient? client,
  Duration connectionTimeout = const Duration(seconds: 15),
  Duration responseTimeout = const Duration(seconds: 30),
  int attemptsPerSource = 2,
  Duration retryDelay = const Duration(milliseconds: 250),
}) async {
  if (attemptsPerSource < 1) {
    throw ArgumentError.value(
      attemptsPerSource,
      'attemptsPerSource',
      'Must be positive.',
    );
  }
  if (await isNativeArtifactValid(destination, artifact)) return destination;

  await destination.parent.create(recursive: true);
  final temporaryDirectory = await destination.parent.createTemp(
    '.berga-trans-dash-native-part-',
  );
  final temporary = File('${temporaryDirectory.path}/artifact');
  final httpClient = client ?? (HttpClient()..connectionTimeout = connectionTimeout);
  final ownsClient = client == null;
  try {
    for (final source in artifact.downloadSources) {
      for (var attempt = 0; attempt < attemptsPerSource; attempt++) {
        try {
          await _downloadFromSource(
            client: httpClient,
            artifact: artifact,
            source: source,
            destination: temporary,
            responseTimeout: responseTimeout,
          );
          if (!await isNativeArtifactValid(temporary, artifact)) {
            throw const _NativeArtifactIntegrityException(
              'Native artifact checksum mismatch.',
            );
          }
          await _promoteTemporaryArtifact(
            temporary: temporary,
            destination: destination,
            artifact: artifact,
          );
          return destination;
        } catch (error) {
          if (await temporary.exists()) await temporary.delete();
          if (attempt + 1 >= attemptsPerSource || !_isRetryable(error)) break;
          await Future<void>.delayed(retryDelay);
        }
      }
    }
    throw StateError(
      'Every berga_trans_dash_native artifact source failed. '
      'For an offline build, populate the Native Assets cache first.',
    );
  } finally {
    if (ownsClient) httpClient.close(force: true);
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  }
}

Future<void> _promoteTemporaryArtifact({
  required File temporary,
  required File destination,
  required NativeArtifact artifact,
}) async {
  try {
    await temporary.rename(destination.path);
  } on FileSystemException {
    if (await isNativeArtifactValid(destination, artifact)) return;
    if (!Platform.isWindows) rethrow;
    if (await destination.exists()) await destination.delete();
    try {
      await temporary.rename(destination.path);
    } on FileSystemException {
      if (!await isNativeArtifactValid(destination, artifact)) rethrow;
    }
  }
}

Future<File> ensureBundledNativeArtifact({
  required File cachedArtifact,
  required File destination,
  required NativeArtifact artifact,
}) async {
  if (!await isNativeArtifactValid(cachedArtifact, artifact)) {
    throw StateError('Cached native artifact failed verification.');
  }
  if (await isNativeArtifactValid(destination, artifact)) return destination;

  await destination.parent.create(recursive: true);
  await cachedArtifact.copy(destination.path);
  if (!await isNativeArtifactValid(destination, artifact)) {
    throw StateError('Bundled native artifact copy failed verification.');
  }
  return destination;
}

Future<void> _downloadFromSource({
  required HttpClient client,
  required NativeArtifact artifact,
  required NativeArtifactDownloadSource source,
  required File destination,
  required Duration responseTimeout,
}) async {
  var uri = source.url;
  final allowedHosts = {
    source.url.host.toLowerCase(),
    ...source.allowedRedirectHosts,
  };
  for (var redirectCount = 0; redirectCount <= 5; redirectCount++) {
    _validateDownloadUri(uri, allowedHosts);
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    final response = await request.close().timeout(responseTimeout);
    if (response.isRedirect) {
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>().timeout(responseTimeout);
      if (location == null) {
        throw const HttpException('Native artifact redirect is missing a URL.');
      }
      uri = uri.resolve(location);
      continue;
    }
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>().timeout(responseTimeout);
      throw _NativeArtifactHttpException(response.statusCode);
    }

    final sink = destination.openWrite(mode: FileMode.writeOnly);
    var receivedBytes = 0;
    try {
      await for (final chunk in response.timeout(responseTimeout)) {
        receivedBytes += chunk.length;
        if (receivedBytes > artifact.size) {
          throw const _NativeArtifactIntegrityException(
            'Native artifact exceeded its declared size.',
          );
        }
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
    if (receivedBytes != artifact.size) {
      throw const _NativeArtifactIntegrityException(
        'Native artifact size mismatch.',
      );
    }
    return;
  }
  throw const HttpException('Too many native artifact redirects.');
}

void _validateDownloadUri(Uri uri, Set<String> allowedHosts) {
  final loopbackHttp = uri.scheme == 'http' &&
      (uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '::1');
  if ((uri.scheme != 'https' && !loopbackHttp) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      !allowedHosts.contains(uri.host.toLowerCase())) {
    throw const _NativeArtifactTrustException(
      'Native artifact redirected to an untrusted URL.',
    );
  }
}

bool _isRetryable(Object error) => switch (error) {
  TimeoutException() || SocketException() || HttpException() =>
    true,
  _NativeArtifactHttpException(:final statusCode) =>
    statusCode == HttpStatus.requestTimeout ||
        statusCode == HttpStatus.tooManyRequests ||
        statusCode >= HttpStatus.internalServerError,
  _ => false,
};

final class _NativeArtifactHttpException implements Exception {
  const _NativeArtifactHttpException(this.statusCode);

  final int statusCode;
}

final class _NativeArtifactIntegrityException implements Exception {
  const _NativeArtifactIntegrityException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class _NativeArtifactTrustException implements Exception {
  const _NativeArtifactTrustException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<bool> isNativeArtifactValid(
  File file,
  NativeArtifact artifact,
) async {
  if (!await file.exists() || await file.length() != artifact.size) {
    return false;
  }
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString() == artifact.sha256;
}
