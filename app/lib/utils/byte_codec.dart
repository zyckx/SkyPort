import 'dart:convert';
import 'dart:typed_data';

/// Display-side byte conversions for the tools page. Transport encoding of
/// sent data remains in the Rust core.

final _hexSeparators = RegExp(r'[\s,]+');
final _hexDigits = RegExp(r'^[0-9a-fA-F]*$');

/// Result of parsing user-typed Hex; [bytes] is null when [error] is set.
typedef HexParse = ({Uint8List? bytes, HexParseError? error});

enum HexParseError { invalidCharacter, oddLength }

/// Parses Hex such as `01 A2,ff`. Optional `0x` prefixes are accepted per
/// token. Never pads or drops digits: odd lengths are rejected.
HexParse parseHex(String input) {
  final tokens = input
      .split(_hexSeparators)
      .where((token) => token.isNotEmpty)
      .map(
        (token) => token.startsWith('0x') || token.startsWith('0X')
            ? token.substring(2)
            : token,
      );
  final digits = tokens.join();
  if (!_hexDigits.hasMatch(digits)) {
    return (bytes: null, error: HexParseError.invalidCharacter);
  }
  if (digits.length.isOdd) {
    return (bytes: null, error: HexParseError.oddLength);
  }
  final bytes = Uint8List(digits.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = int.parse(digits.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return (bytes: bytes, error: null);
}

/// Formats bytes as upper-case Hex separated by single spaces.
String formatHex(Uint8List bytes) => bytes
    .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(' ');

/// UTF-8 bytes of [text].
Uint8List textBytes(String text) => Uint8List.fromList(utf8.encode(text));

/// Decodes [bytes] as UTF-8 for display. Invalid sequences and control
/// characters are shown as `\xHH` escapes so no byte is hidden.
String describeBytes(Uint8List bytes) {
  final buffer = StringBuffer();
  var index = 0;
  while (index < bytes.length) {
    final length = _utf8SequenceLength(bytes, index);
    if (length == 0) {
      buffer.write(_escape(bytes[index]));
      index++;
      continue;
    }
    final text = utf8.decode(bytes.sublist(index, index + length));
    final rune = text.runes.first;
    if (rune < 0x20 || rune == 0x7f) {
      buffer.write(switch (rune) {
        0x0a => r'\n',
        0x0d => r'\r',
        0x09 => r'\t',
        _ => _escape(rune),
      });
    } else {
      buffer.write(text);
    }
    index += length;
  }
  return buffer.toString();
}

String _escape(int byte) =>
    '\\x${byte.toRadixString(16).padLeft(2, '0').toUpperCase()}';

/// Length of the valid UTF-8 sequence at [start], or 0 if invalid.
int _utf8SequenceLength(Uint8List bytes, int start) {
  final lead = bytes[start];
  final int length;
  final int minimum;
  if (lead < 0x80) {
    return 1;
  } else if (lead >= 0xc2 && lead <= 0xdf) {
    (length, minimum) = (2, 0x80);
  } else if (lead >= 0xe0 && lead <= 0xef) {
    (length, minimum) = (3, 0x800);
  } else if (lead >= 0xf0 && lead <= 0xf4) {
    (length, minimum) = (4, 0x10000);
  } else {
    return 0;
  }
  if (start + length > bytes.length) return 0;
  var codePoint = lead & (0xff >> (length + 1));
  for (var i = 1; i < length; i++) {
    final next = bytes[start + i];
    if (next & 0xc0 != 0x80) return 0;
    codePoint = (codePoint << 6) | (next & 0x3f);
  }
  if (codePoint < minimum ||
      codePoint > 0x10ffff ||
      (codePoint >= 0xd800 && codePoint <= 0xdfff)) {
    return 0;
  }
  return length;
}

/// Radixes supported by the number converter.
enum NumberBase {
  binary(2, 'BIN'),
  octal(8, 'OCT'),
  decimal(10, 'DEC'),
  hexadecimal(16, 'HEX');

  const NumberBase(this.radix, this.label);

  final int radix;
  final String label;
}

/// Parses a non-negative integer in [base]; spaces, underscores and the
/// conventional `0b`/`0o`/`0x` prefix are ignored. Returns null if invalid.
BigInt? parseNumber(String input, NumberBase base) {
  var text = input.replaceAll(RegExp(r'[\s_]'), '').toLowerCase();
  final prefix = switch (base) {
    NumberBase.binary => '0b',
    NumberBase.octal => '0o',
    NumberBase.hexadecimal => '0x',
    NumberBase.decimal => null,
  };
  if (prefix != null && text.startsWith(prefix)) text = text.substring(2);
  if (text.isEmpty) return null;
  final valid = switch (base) {
    NumberBase.binary => RegExp(r'^[01]+$'),
    NumberBase.octal => RegExp(r'^[0-7]+$'),
    NumberBase.decimal => RegExp(r'^[0-9]+$'),
    NumberBase.hexadecimal => RegExp(r'^[0-9a-f]+$'),
  };
  if (!valid.hasMatch(text)) return null;
  return BigInt.parse(text, radix: base.radix);
}

String formatNumber(BigInt value, NumberBase base) =>
    value.toRadixString(base.radix).toUpperCase();
