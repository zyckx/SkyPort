import 'ui_state.dart';

/// A user-saved command. Encoding of [payload] (text plus [newline], or
/// Hex) happens in the Rust core when it is sent.
class QuickCommand {
  const QuickCommand({
    required this.id,
    required this.name,
    required this.payload,
    required this.hex,
    required this.newline,
  });

  final String id;
  final String name;
  final String payload;
  final bool hex;

  /// Line ending appended to text commands; ignored for Hex.
  final UiNewline newline;

  QuickCommand copyWith({
    String? name,
    String? payload,
    bool? hex,
    UiNewline? newline,
  }) => QuickCommand(
    id: id,
    name: name ?? this.name,
    payload: payload ?? this.payload,
    hex: hex ?? this.hex,
    newline: newline ?? this.newline,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'payload': payload,
    'hex': hex,
    'newline': newline.name,
  };

  /// Returns null for malformed entries so one bad record cannot drop the
  /// rest of the list.
  static QuickCommand? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    final payload = json['payload'];
    final hex = json['hex'];
    if (id is! String ||
        name is! String ||
        payload is! String ||
        hex is! bool) {
      return null;
    }
    final newline = UiNewline.values.firstWhere(
      (value) => value.name == json['newline'],
      orElse: () => UiNewline.none,
    );
    return QuickCommand(
      id: id,
      name: name,
      payload: payload,
      hex: hex,
      newline: newline,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QuickCommand &&
      other.id == id &&
      other.name == name &&
      other.payload == payload &&
      other.hex == hex &&
      other.newline == newline;

  @override
  int get hashCode => Object.hash(id, name, payload, hex, newline);
}
