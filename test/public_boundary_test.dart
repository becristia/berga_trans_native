// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public package contains only the translation loader boundary', () {
    final root = Directory.current;
    final paths = root
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path.substring(root.path.length + 1))
        .where((path) => !path.startsWith('.dart_tool/'))
        .toList(growable: false);
    final prohibitedPaths = RegExp(
      r'(^|/)(language_detection|detection|engine|catalog|worker|ffi|rust|cld2|fasttext|lingua)(/|[_.-])',
      caseSensitive: false,
    );

    expect(paths.where(prohibitedPaths.hasMatch), isEmpty);
    expect(paths.where((path) => path.endsWith('.cpp')), isEmpty);
    expect(paths.where((path) => path.endsWith('.rs')), isEmpty);
  });

  test('public code and ABI expose no language-identification symbols', () {
    const checkedRoots = ['lib', 'hook', 'src'];
    final source = checkedRoots
        .expand(
          (path) => Directory(path)
              .listSync(recursive: true)
              .whereType<File>()
              .map((file) => file.readAsStringSync()),
        )
        .join('\n');
    final prohibitedSymbols = RegExp(
      r'ot_(statistical_lid|lingua)|language_detection|lidBackend|linguaProfile|cld2|fasttext',
      caseSensitive: false,
    );

    expect(prohibitedSymbols.hasMatch(source), isFalse);
  });
}
