import 'dart:convert';
import 'dart:io';

// Only the reader: the package barrel pulls in path_provider, which cannot run outside Flutter.
import 'package:chili_localization/src/push/arb_reader.dart';
import 'package:http/http.dart' as http;

const _apiKeyEnv = 'CHILI_LOCALIZATION_API_KEY';
const _defaultArbDir = 'resources/translations';
const _defaultEndpoint = 'https://europe-west1-localisation-service-2056b.cloudfunctions.net/pushArb';
const _usage = '''
Adds ARB keys that the Localization Service project does not have yet. Existing keys are never changed.

Usage: dart run chili_localization:push --project <id> [--arb-dir <dir>] [--dry-run] [--endpoint <url>]
The project API key is read from the $_apiKeyEnv environment variable.''';

Future<void> main(List<String> args) async {
  final projectId = _option(args, '--project');
  final arbDir = _option(args, '--arb-dir') ?? _defaultArbDir;
  final endpoint = _option(args, '--endpoint') ?? _defaultEndpoint;
  final dryRun = args.contains('--dry-run');
  final apiKey = Platform.environment[_apiKeyEnv];

  if (projectId == null) _fail(_usage, exitCode: 2);
  if (apiKey == null || apiKey.isEmpty) _fail('$_apiKeyEnv is not set.\n\n$_usage', exitCode: 2);

  final directory = Directory(arbDir);
  if (!directory.existsSync()) _fail('ARB directory "$arbDir" does not exist.', exitCode: 2);

  final files = readArbFiles(directory);
  if (files.isEmpty) _fail('No .arb files found in "$arbDir".', exitCode: 2);

  final http.Response response;
  try {
    response = await http.post(
      Uri.parse(endpoint),
      headers: {'content-type': 'application/json', 'x-api-key': apiKey},
      body: jsonEncode({'projectId': projectId, 'dryRun': dryRun, 'files': files}),
    );
  } on Exception catch (error) {
    _fail('Request to $endpoint failed: $error');
  }

  if (response.statusCode != 200) _fail('Push failed (${response.statusCode}): ${response.body}');

  final result = jsonDecode(response.body) as Map<String, dynamic>;
  final added = List<String>.from(result['added'] as List);
  final skippedLocales = List<String>.from(result['skippedLocales'] as List);
  final skippedKeys = List<String>.from(result['skippedKeys'] as List);

  stdout.writeln(dryRun ? 'Would add ${added.length} key(s):' : 'Added ${added.length} key(s):');
  for (final key in added) {
    stdout.writeln('  $key');
  }
  if (skippedLocales.isNotEmpty) {
    stdout.writeln('Warning: skipped locales not supported by the project: ${skippedLocales.join(', ')}');
  }
  if (skippedKeys.isNotEmpty) {
    stdout.writeln('Warning: skipped invalid keys or non-string values: ${skippedKeys.join(', ')}');
  }
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);

  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

Never _fail(String message, {int exitCode = 1}) {
  stderr.writeln(message);
  exit(exitCode);
}
