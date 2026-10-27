import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skyport/utils/checksum.dart';

Uint8List _ascii(String text) => Uint8List.fromList(ascii.encode(text));

void main() {
  // Standard catalogue check values for the input "123456789".
  final check = _ascii('123456789');

  test('algorithms match their catalogue check values', () {
    expect(computeCrc16Modbus(check), 0x4b37);
    expect(computeCrc16CcittFalse(check), 0x29b1);
    expect(computeCrc32(check), 0xcbf43926);
    expect(computeXor8(check), 0x31);
    expect(computeSum8(check), 0xdd);
  });

  test('empty input yields each algorithm initial value', () {
    final empty = Uint8List(0);
    expect(computeCrc16Modbus(empty), 0xffff);
    expect(computeCrc16CcittFalse(empty), 0xffff);
    expect(computeCrc32(empty), 0);
    expect(computeXor8(empty), 0);
    expect(computeSum8(empty), 0);
  });

  test('sum wraps at one byte and results fit their declared width', () {
    expect(computeSum8(Uint8List.fromList([0xff, 0x02])), 0x01);
    final data = Uint8List.fromList(List.generate(1024, (i) => i & 0xff));
    for (final algorithm in ChecksumAlgorithm.values) {
      final value = algorithm.compute(data);
      expect(value, inInclusiveRange(0, (1 << (algorithm.width * 8)) - 1));
      expect(checksumBytes(value, algorithm.width), hasLength(algorithm.width));
    }
  });

  test('checksum bytes are big-endian', () {
    expect(checksumBytes(0x4b37, 2), [0x4b, 0x37]);
    expect(checksumBytes(0xcbf43926, 4), [0xcb, 0xf4, 0x39, 0x26]);
  });
}
