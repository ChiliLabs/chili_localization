final class RemoteLocalizationManager {
  static final _simplePlaceholderRegex = RegExp(r'\{(\w+)\}');
  static final _icuHeader = RegExp(r'^\{(\w+),\s*(plural|select|selectordinal),');
  static final _caseRegex = RegExp(r'([^\s{}]+)\s*\{((?:[^{}]|\{[^{}]*\})*)\}');

  static Map<String, Map<String, dynamic>> _translations = {};

  static void setTranslations(Map<String, Map<String, dynamic>> translations) {
    _translations = translations;
  }

  static String? getText(String locale, String key, [Map<String, dynamic> args = const {}]) {
    try {
      final translationKey = _translations[key];
      if (translationKey == null) {
        return null;
      }

      var translation = translationKey[locale] as String;

      translation = _handleICU(translation, args);

      translation = translation.replaceAllMapped(_simplePlaceholderRegex, (match) {
        final key = match.group(1);
        final value = args[key];

        return value?.toString() ?? '';
      });

      return translation;
    } catch (ex) {
      return null;
    }
  }

  static String _handleICU(String input, Map<String, dynamic> args) {
    final buffer = StringBuffer();
    var index = 0;

    while (index < input.length) {
      if (input[index] == '{') {
        var braceStart = index;
        var depth = 0;
        do {
          final char = input[index];
          if (char == '{') depth++;
          if (char == '}') depth--;
          index++;
        } while (index < input.length && depth > 0);

        final icuBlock = input.substring(braceStart, index);
        final parsed = _parseICUBlock(icuBlock, args);
        buffer.write(parsed);
      } else {
        buffer.write(input[index]);
        index++;
      }
    }

    return buffer.toString();
  }

  static String _parseICUBlock(String block, Map<String, dynamic> args) {
    final match = _icuHeader.firstMatch(block);
    if (match == null) return block;

    final variable = match.group(1);
    final value = args[variable]?.toString() ?? 'other';

    final casesBlock = block.substring(match.end, block.length - 1);

    final cases = <String, String>{};
    for (final m in _caseRegex.allMatches(casesBlock)) {
      final key = m.group(1);
      final val = m.group(2);

      if (key != null && val != null) {
        cases[key] = val;
      }
    }

    return cases[value] ?? cases['other'] ?? '';
  }
}
