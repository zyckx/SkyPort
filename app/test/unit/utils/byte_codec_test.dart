import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skyport/utils/byte_codec.dart';

void main() {
  group('parseHex', () {
    test('accepts separators and 0x prefixes without altering bytes', () {
      final result = parseHex(' 01 a2,FF\n0x10 ');
      expect(result.error, isNull);
      expect(result.bytes, [0x01, 0xa2, 0xff, 0x10]);
    });

    test('rejects odd lengths instead of padding', () {
      expect(parseHex('ABC').error, HexParseError.oddLength);
      expect(parseHex('ABC').bytes, isNull);
    });

    test('rejects non-hex characters', () {
      expect(parseHex('0G').error, HexParseError.invalidCharacter);
    });

    test('empty input is an empty byte sequence', () {
      expect(parseHex('  ').bytes, isEmpty);
    });
  });

  test('formatHex round-trips through parseHex', () {
    final bytes = Uint8List.fromList([0, 15, 16, 255]);
    expect(formatHex(bytes), '00 0F 10 FF');
    expect(parseHex(formatHex(bytes)).bytes, bytes);
  });

  test('textBytes encodes UTF-8 exactly', () {
    expect(textBytes('中A'), [0xe4, 0xb8, 0xad, 0x41]);
  });

  group('describeBytes', () {
    test('shows valid UTF-8 and escapes controls', () {
      expect(
        describeBytes(Uint8List.fromList([0x48, 0x0d, 0x0a, 0xe4, 0xb8, 0xad])),
        r'H\r\n中',
      );
    });

    test('never hides invalid or truncated sequences', () {
      expect(
        describeBytes(Uint8List.fromList([0xff, 0x41, 0xe4, 0xb8])),
        r'\xFFA\xE4\xB8',
      );
      expect(describeBytes(Uint8List.fromList([0x00, 0x7f])), r'\x00\x7F');
    });

    test('rejects overlong and surrogate encodings', () {
      expect(describeBytes(Uint8List.fromList([0xc0, 0xaf])), r'\xC0\xAF');
      expect(
        describeBytes(Uint8List.fromList([0xed, 0xa0, 0x80])),
        r'\xED\xA0\x80',
      );
    });
  });

  group('number conversion', () {
    test('parses each base with optional prefixes and separators', () {
      expect(parseNumber('0b1010_1010', NumberBase.binary), BigInt.from(170));
      expect(parseNumber('0o777', NumberBase.octal), BigInt.from(511));
      expect(parseNumber('1 000', NumberBase.decimal), BigInt.from(1000));
      expect(parseNumber('0xFF', NumberBase.hexadecimal), BigInt.from(255));
    });

    test('rejects digits outside the base and empty input', () {
      expect(parseNumber('102', NumberBase.binary), isNull);
      expect(parseNumber('8', NumberBase.octal), isNull);
      expect(parseNumber('', NumberBase.decimal), isNull);
      expect(parseNumber('-1', NumberBase.decimal), isNull);
    });

    test('handles values beyond 64 bits', () {
      final value = parseNumber('FFFFFFFFFFFFFFFFFF', NumberBase.hexadecimal)!;
      expect(formatNumber(value, NumberBase.hexadecimal), 'FFFFFFFFFFFFFFFFFF');
      expect(formatNumber(value, NumberBase.decimal), '4722366482869645213695');
    });
  });
}
