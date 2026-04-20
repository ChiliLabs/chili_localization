import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final input = args.firstOrNull ?? 'resources/translations/app_en.arb';
  final output = args.lastOrNull ?? 'lib/generated/translations/remote_fallback_localization.dart';
  var appLocalizationsFileName = 'app_localizations.dart';
  var useNamedParameters = false;

  try {
    final yamlFile = File('l10n.yaml');
    if (!yamlFile.existsSync()) throw Exception();
    final data = loadYaml(yamlFile.readAsStringSync());
    if (data is YamlMap) {
      final localOutputFileName = data['output-localization-file'];
      final useNamedParametersValue = data['use-named-parameters'];

      if (localOutputFileName is String) appLocalizationsFileName = localOutputFileName;
      if (useNamedParametersValue is bool) useNamedParameters = useNamedParametersValue;
    }
  } catch (ex) {
    print('Warning: Failed to read l10n.yaml file, will use default configuration.');
  }

  final file = File(input);

  if (!file.existsSync()) {
    exit(1);
  }

  final icuRegex = RegExp(r'\{(\w+),\s*(plural|select|selectordinal)[^}]*\}');
  final simplePlaceholderRegex = RegExp(r'\{(\w+)\}');
  final icuBlockRegex = RegExp(r'\{(\w+),\s*(plural|select|selectordinal),((?:[^{}]|\{[^{}]*\})*)\}');

  final Map<String, dynamic> arbJson = json.decode(file.readAsStringSync());

  final keys = arbJson.keys.where((k) => !k.startsWith('@')).toList();
  final placeholdersMap = <String, List<String>>{};

  for (final key in keys) {
    final rawValue = arbJson[key];
    final value = rawValue.toString();

    final placeholders = SplayTreeSet<String>();

    final icuMatches = icuRegex.allMatches(value);
    for (final match in icuMatches) {
      final name = match.group(1);
      if (name != null) {
        placeholders.add(name);
      }
    }

    var cleanedValue = value;
    cleanedValue = cleanedValue.replaceAllMapped(icuBlockRegex, (match) => '');

    final simpleMatches = simplePlaceholderRegex.allMatches(cleanedValue);
    for (final match in simpleMatches) {
      final name = match.group(1);
      if (name != null) {
        placeholders.add(name);
      }
    }

    placeholdersMap[key] = placeholders.toList();
  }

  final buffer = StringBuffer();

  buffer.writeln('// GENERATED FILE - DO NOT MODIFY BY HAND.');
  buffer.writeln('// ignore_for_file: member-ordering, avoid-explicit-type-declaration, avoid-dynamic');
  buffer.writeln('import \'$appLocalizationsFileName\';');
  buffer.writeln('import \'package:chili_localization/src/remote_localization_manager.dart\';');
  buffer.writeln('import \'package:flutter/material.dart\';');
  buffer.writeln('import \'package:flutter_localizations/flutter_localizations.dart\';');
  buffer.writeln(' ');
  buffer.writeln('class RemoteFallbackLocalization extends AppLocalizations {');
  buffer.writeln('  final AppLocalizations fallback;');
  buffer.writeln(' ');
  buffer.writeln('  RemoteFallbackLocalization({');
  buffer.writeln('    required Locale locale,');
  buffer.writeln('    required this.fallback,');
  buffer.writeln('  }) : super(locale.languageCode);');
  buffer.writeln(' ');
  buffer.writeln(
    '  static const LocalizationsDelegate<AppLocalizations> delegate = _RemoteFallbackLocalizationDelegate();',
  );
  buffer.writeln(' ');
  buffer.writeln(
    '  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[',
  );
  buffer.writeln('    delegate,');
  buffer.writeln('    GlobalMaterialLocalizations.delegate,');
  buffer.writeln('    GlobalCupertinoLocalizations.delegate,');
  buffer.writeln('    GlobalWidgetsLocalizations.delegate,');
  buffer.writeln('  ];');
  buffer.writeln(' ');
  buffer.writeln('  static const List<Locale> supportedLocales = AppLocalizations.supportedLocales;');

  for (final key in keys) {
    final placeholders = placeholdersMap[key] ?? [];
    if (placeholders.isEmpty) {
      buffer.writeln('  @override');
      buffer.writeln('  String get $key => RemoteLocalizationManager.getText(localeName, \'$key\') ?? fallback.$key;');
      buffer.writeln(' ');
    } else {
      final params = placeholders.map((p) => 'dynamic $p').join(', ');
      final argsMap = placeholders.map((p) => "'$p': $p").join(', ');

      final namedParams = placeholders.map((p) => 'required dynamic $p').join(', ');
      final namedFallbacks = placeholders.map((p) => "$p: $p").join(', ');

      final paramsFormatted = useNamedParameters ? '{ $namedParams }' : params;
      final fallbacks = useNamedParameters ? '{ $namedFallbacks }' : placeholders.join(', ');

      buffer.writeln('  @override');
      buffer.writeln(
        '  String $key($paramsFormatted) => RemoteLocalizationManager.getText(localeName, \'$key\', { $argsMap }) ?? fallback.$key($fallbacks);',
      );
      buffer.writeln(' ');
    }
  }

  buffer.writeln('}');

  buffer.writeln(' ');
  buffer.writeln('class _RemoteFallbackLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {');
  buffer.writeln('  const _RemoteFallbackLocalizationDelegate();');
  buffer.writeln(' ');
  buffer.writeln('  @override');
  buffer.writeln('  Future<AppLocalizations> load(Locale locale) =>');
  buffer.writeln('    AppLocalizations.delegate.load(locale)');
  buffer.writeln('      .then((fallback) => RemoteFallbackLocalization(locale: locale, fallback: fallback));');
  buffer.writeln(' ');
  buffer.writeln('  @override');
  buffer.writeln('  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.contains(locale);');
  buffer.writeln(' ');
  buffer.writeln('  @override');
  buffer.writeln('  bool shouldReload(_RemoteFallbackLocalizationDelegate old) => false;');
  buffer.writeln('}');

  final outputFile = File(output);
  outputFile.writeAsStringSync(buffer.toString());

  print(
    '✅ Generated localization with ${keys.length} keys at lib/generated/translations/remote_fallback_localization.dart',
  );
}
