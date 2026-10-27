import 'dart:typed_data';

/// Checksum algorithms offered by the tools page. These only compute values
/// for the user to inspect or copy; nothing is appended to transmissions.
enum ChecksumAlgorithm {
  crc16Modbus('CRC-16/MODBUS', 2),
  crc16CcittFalse('CRC-16/CCITT-FALSE', 2),
  crc32('CRC-32', 4),
  xor8('XOR-8', 1),
  sum8('SUM-8', 1);

  const ChecksumAlgorithm(this.label, this.width);

  final String label;

  /// Result width in bytes.
  final int width;

  int compute(Uint8List data) => switch (this) {
    ChecksumAlgorithm.crc16Modbus => computeCrc16Modbus(data),
    ChecksumAlgorithm.crc16CcittFalse => computeCrc16CcittFalse(data),
    ChecksumAlgorithm.crc32 => computeCrc32(data),
    ChecksumAlgorithm.xor8 => computeXor8(data),
    ChecksumAlgorithm.sum8 => computeSum8(data),
  };
}

/// CRC-16/MODBUS: reflected poly 0x8005 (0xA001), init 0xFFFF.
int computeCrc16Modbus(Uint8List data) {
  var crc = 0xffff;
  for (final byte in data) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xa001 : crc >> 1;
    }
  }
  return crc & 0xffff;
}

/// CRC-16/CCITT-FALSE: poly 0x1021, init 0xFFFF, not reflected.
int computeCrc16CcittFalse(Uint8List data) {
  var crc = 0xffff;
  for (final byte in data) {
    crc ^= byte << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
    }
  }
  return crc & 0xffff;
}

/// CRC-32 (IEEE 802.3): reflected poly 0x04C11DB7, init and xorout 0xFFFFFFFF.
int computeCrc32(Uint8List data) {
  var crc = 0xffffffff;
  for (final byte in data) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

int computeXor8(Uint8List data) => data.fold(0, (acc, byte) => acc ^ byte);

int computeSum8(Uint8List data) =>
    data.fold(0, (acc, byte) => acc + byte) & 0xff;

/// Big-endian bytes of [value] for an algorithm of [width] bytes.
Uint8List checksumBytes(int value, int width) => Uint8List.fromList([
  for (var i = width - 1; i >= 0; i--) (value >> (8 * i)) & 0xff,
]);
