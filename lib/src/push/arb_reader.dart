import 'dart:convert';
import 'dart:io';

// Same rule as gen-l10n: everything after the first `_` is the locale (`app_en_US.arb` -> `en_US`).
final _localeFromFileName = RegExp(r'^[^_]*_(\w+)\.arb$');

/// Reads every `.arb` file in [directory], keyed by locale.
///
/// The locale comes from `@@locale` when present, otherwise from the file name.
/// Files whose locale cannot be determined are skipped.
Map<String, Map<String, dynamic>> readArbFiles(Directory directory) {
  final files = <String, Map<String, dynamic>>{};

  for (final file in directory.listSync().whereType<File>()) {
    final fileName = file.uri.pathSegments.last;
    if (!fileName.endsWith('.arb')) continue;

    final content = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final locale = content['@@locale'] as String? ?? _localeFromFileName.firstMatch(fileName)?.group(1);
    if (locale == null) continue;

    files[locale] = content;
  }

  return files;
}
