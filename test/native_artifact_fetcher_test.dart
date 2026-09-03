// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';

import 'package:berga_trans_dash_native/src/hook/native_artifact_fetcher.dart';
import 'package:berga_trans_dash_native/src/hook/native_artifact_manifest.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ot_artifact_test_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('downloads once and reuses a valid cached artifact', () async {
    final bytes = utf8.encode('native artifact fixture');
    final server = await _ArtifactServer.start(bytes: bytes);
    addTearDown(server.close);
    final artifact = _artifact(server.uri, bytes);
    final destination = File('${root.path}/cache/library.so');

    await ensureNativeArtifact(
      artifact: artifact,
      destination: destination,
    );
    await ensureNativeArtifact(
      artifact: artifact,
      destination: destination,
    );

    expect(await destination.readAsBytes(), bytes);
    expect(server.requests, 1);
  });

  test('replaces an invalid cached artifact', () async {
    final bytes = utf8.encode('valid native artifact');
    final server = await _ArtifactServer.start(bytes: bytes);
    addTearDown(server.close);
    final destination = File('${root.path}/cache/library.so');
    await destination.parent.create(recursive: true);
    await destination.writeAsString('corrupt');

    await ensureNativeArtifact(
      artifact: _artifact(server.uri, bytes),
      destination: destination,
    );

    expect(await destination.readAsBytes(), bytes);
    expect(server.requests, 1);
  });

  test(
    'updates a stable bundled copy when the selected artifact changes',
    () async {
      final firstBytes = utf8.encode('first native artifact');
      final secondBytes = utf8.encode('second artifact with a new identity');
      final firstCache = File('${root.path}/cache/first/library.so');
      final secondCache = File('${root.path}/cache/second/library.so');
      final bundled = File('${root.path}/bundled/android/library.so');
      await firstCache.parent.create(recursive: true);
      await secondCache.parent.create(recursive: true);
      await firstCache.writeAsBytes(firstBytes);
      await secondCache.writeAsBytes(secondBytes);

      await ensureBundledNativeArtifact(
        cachedArtifact: firstCache,
        destination: bundled,
        artifact: _artifact(
          Uri.parse('https://example.invalid/first'),
          firstBytes,
        ),
      );
      await ensureBundledNativeArtifact(
        cachedArtifact: secondCache,
        destination: bundled,
        artifact: _artifact(
          Uri.parse('https://example.invalid/second'),
          secondBytes,
        ),
      );

      expect(await bundled.readAsBytes(), secondBytes);
      expect(await firstCache.readAsBytes(), firstBytes);
      expect(await secondCache.readAsBytes(), secondBytes);
    },
  );

  test('rejects a checksum mismatch without retaining partial data', () async {
    final bytes = utf8.encode('corrupt native artifact');
    final server = await _ArtifactServer.start(bytes: bytes);
    addTearDown(server.close);
    final destination = File('${root.path}/cache/library.so');
    final artifact = NativeArtifact(
      os: 'android',
      architecture: 'arm64',
      environment: 'android',
      fileName: 'library.so',
      downloadSources: [_source(server.uri)],
      correspondingSourceIds: const ['bergamot-mpl-source'],
      size: bytes.length,
      sha256: List.filled(64, '0').join(),
    );

    await expectLater(
      ensureNativeArtifact(artifact: artifact, destination: destination),
      throwsA(isA<StateError>()),
    );

    expect(await destination.exists(), isFalse);
    expect(await File('${destination.path}.part').exists(), isFalse);
    expect(server.requests, 1);
  });

  test('concurrent cache fills use independent temporary files', () async {
    final bytes = utf8.encode('concurrent native artifact');
    final server = await _ArtifactServer.start(
      bytes: bytes,
      responseDelay: const Duration(milliseconds: 20),
    );
    addTearDown(server.close);
    final artifact = _artifact(server.uri, bytes);
    final destination = File('${root.path}/cache/library.so');

    final results = await Future.wait([
      ensureNativeArtifact(artifact: artifact, destination: destination),
      ensureNativeArtifact(artifact: artifact, destination: destination),
    ]);

    expect(results.map((file) => file.path), everyElement(destination.path));
    expect(await destination.readAsBytes(), bytes);
    expect(
      destination.parent
          .listSync(followLinks: false)
          .where(
            (entry) =>
                entry.path.contains('.berga-trans-dash-native-part-'),
          ),
      isEmpty,
    );
  });

  test('reports an HTTP failure', () async {
    final server = await _ArtifactServer.start(
      bytes: const [],
      statusCode: HttpStatus.internalServerError,
    );
    addTearDown(server.close);
    final artifact = _artifact(server.uri, const []);

    await expectLater(
      ensureNativeArtifact(
        artifact: artifact,
        destination: File('${root.path}/cache/library.so'),
      ),
      throwsA(isA<StateError>()),
    );
    expect(server.requests, 2);
  });

  test('offline failure explains how to populate the cache', () async {
    final closedServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final uri = Uri.parse(
      'http://${closedServer.address.address}:${closedServer.port}/library.so',
    );
    await closedServer.close(force: true);
    final artifact = _artifact(uri, const []);

    await expectLater(
      ensureNativeArtifact(
        artifact: artifact,
        destination: File('${root.path}/cache/library.so'),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('populate the Native Assets cache first'),
        ),
      ),
    );
  });

  test('falls back to the next source after primary failures', () async {
    final bytes = utf8.encode('fallback native artifact');
    final primary = await _ArtifactServer.start(
      bytes: const [],
      statusCode: HttpStatus.internalServerError,
    );
    final fallback = await _ArtifactServer.start(bytes: bytes);
    addTearDown(primary.close);
    addTearDown(fallback.close);
    final destination = File('${root.path}/cache/library.so');
    final artifact = _artifactFromSources(
      [primary.uri, fallback.uri],
      bytes,
    );

    await ensureNativeArtifact(
      artifact: artifact,
      destination: destination,
      retryDelay: Duration.zero,
    );

    expect(await destination.readAsBytes(), bytes);
    expect(primary.requests, 2);
    expect(fallback.requests, 1);
  });

  test('times out a stalled source without retaining partial data', () async {
    final bytes = utf8.encode('slow native artifact');
    final server = await _ArtifactServer.start(
      bytes: bytes,
      responseDelay: const Duration(milliseconds: 100),
    );
    addTearDown(server.close);
    final destination = File('${root.path}/cache/library.so');

    await expectLater(
      ensureNativeArtifact(
        artifact: _artifact(server.uri, bytes),
        destination: destination,
        responseTimeout: const Duration(milliseconds: 10),
        attemptsPerSource: 1,
      ),
      throwsA(isA<StateError>()),
    );

    expect(await destination.exists(), isFalse);
    expect(await File('${destination.path}.part').exists(), isFalse);
  });

  test('rejects a redirect to a host outside the source allowlist', () async {
    final bytes = utf8.encode('redirected native artifact');
    final destinationServer = await _ArtifactServer.start(bytes: bytes);
    final redirectedUri = destinationServer.uri.replace(host: 'localhost');
    final sourceServer = await _ArtifactServer.start(
      bytes: const [],
      redirectTo: redirectedUri,
    );
    addTearDown(sourceServer.close);
    addTearDown(destinationServer.close);

    await expectLater(
      ensureNativeArtifact(
        artifact: _artifact(sourceServer.uri, bytes),
        destination: File('${root.path}/cache/library.so'),
      ),
      throwsA(isA<StateError>()),
    );

    expect(destinationServer.requests, 0);
    expect(sourceServer.requests, 1);
  });
}

NativeArtifact _artifact(Uri uri, List<int> bytes) => NativeArtifact(
  os: 'android',
  architecture: 'arm64',
  environment: 'android',
  fileName: 'library.so',
  downloadSources: [_source(uri)],
  correspondingSourceIds: const ['bergamot-mpl-source'],
  size: bytes.length,
  sha256: sha256.convert(bytes).toString(),
);

NativeArtifact _artifactFromSources(List<Uri> uris, List<int> bytes) =>
    NativeArtifact(
      os: 'android',
      architecture: 'arm64',
      environment: 'android',
      fileName: 'library.so',
      downloadSources: uris.map(_source).toList(growable: false),
      correspondingSourceIds: const ['bergamot-mpl-source'],
      size: bytes.length,
      sha256: sha256.convert(bytes).toString(),
    );

NativeArtifactDownloadSource _source(Uri uri) =>
    NativeArtifactDownloadSource(url: uri, allowedRedirectHosts: const {});

final class _ArtifactServer {
  _ArtifactServer._(this._server, this.uri);

  final HttpServer _server;
  final Uri uri;
  var requests = 0;

  static Future<_ArtifactServer> start({
    required List<int> bytes,
    int statusCode = HttpStatus.ok,
    Duration responseDelay = Duration.zero,
    Uri? redirectTo,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _ArtifactServer._(
      server,
      Uri.parse(
        'http://${server.address.address}:${server.port}/library.so',
      ),
    );
    server.listen((request) async {
      fixture.requests++;
      if (responseDelay > Duration.zero) {
        await Future<void>.delayed(responseDelay);
      }
      try {
        if (redirectTo != null) {
          request.response.statusCode = HttpStatus.temporaryRedirect;
          request.response.headers.set(
            HttpHeaders.locationHeader,
            redirectTo.toString(),
          );
        } else {
          request.response.statusCode = statusCode;
          if (statusCode == HttpStatus.ok) request.response.add(bytes);
        }
        await request.response.close();
      } on HttpException {
        // A timeout may close the client before this fixture responds.
      }
    });
    return fixture;
  }

  Future<void> close() => _server.close(force: true);
}
