import 'dart:convert';
import 'dart:io';

import 'package:chili_localization/src/remote_localization_manager.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

final class RemoteLocalizationClient {
  static const _fileName = 'translations.json';

  static late String _remoteTranslationsUrl;

  static void init({
    required String remoteTranslationsUrl,
  }) {
    _remoteTranslationsUrl = remoteTranslationsUrl;
  }

  static Future<void> loadTranslations({
    required int currentVersion,
    required int remoteVersion,
    required Function(int newVersion) onAppliedNewVersion,
  }) async {
    if (remoteVersion > currentVersion) {
      final response = await http.get(Uri.parse(_remoteTranslationsUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        final translations = jsonMap.map((k, v) => MapEntry(k, v as Map<String, dynamic>? ?? {}));

        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_fileName');
        await file.writeAsString(response.body);

        onAppliedNewVersion(remoteVersion);

        RemoteLocalizationManager.setTranslations(translations);
      }

      await _applyLocalTranslations();
    }

    await _applyLocalTranslations();
  }

  static Future<void> _applyLocalTranslations() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');
    if (file.existsSync()) {
      final content = await file.readAsString();
      final Map<String, dynamic> jsonMap = json.decode(content);

      final translations = jsonMap.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
      RemoteLocalizationManager.setTranslations(translations);
    }
  }
}
