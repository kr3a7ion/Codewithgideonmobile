import 'package:codewithgideon/src/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moment prefix formats the playback time', () {
    expect(momentPrefix('1900'), 'At 31:40: ');
    expect(momentPrefix('5400'), 'At 1:30:00: ');
    expect(momentPrefix('7'), 'At 0:07: ');
  });

  test('moment prefix is empty without a valid time', () {
    expect(momentPrefix(null), '');
    expect(momentPrefix('abc'), '');
    expect(momentPrefix('0'), '');
  });
}
