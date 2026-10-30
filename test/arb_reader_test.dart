import 'dart:io';

import 'package:chili_localization/src/push/arb_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('arb_reader_test'));

  tearDown(() => directory.deleteSync(recursive: true));

  test('TC10: locale from @@locale wins over the file name', () {
    File('${directory.path}/app_en.arb').writeAsStringSync('{"@@locale": "en_US", "a": "A"}');

    final files = readArbFiles(directory);

    expect(files.keys, ['en_US']);
  });

  test('TC11: locale from the file name, non-arb files ignored', () {
    File('${directory.path}/app_lv.arb').writeAsStringSync('{"a": "A"}');
    File('${directory.path}/app_en_US.arb').writeAsStringSync('{"b": "B"}');
    File('${directory.path}/notes.txt').writeAsStringSync('notes');

    final files = readArbFiles(directory);

    expect(files, {
      'lv': {'a': 'A'},
      'en_US': {'b': 'B'},
    });
  });
}
