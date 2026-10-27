import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../models/ui_state.dart';
import '../../providers/ui_controller.dart';
import '../ui/ui.dart';

class SendInputWidget extends ConsumerStatefulWidget {
  const SendInputWidget({super.key});

  @override
  ConsumerState<SendInputWidget> createState() => _SendInputWidgetState();
}

class _SendInputWidgetState extends ConsumerState<SendInputWidget> {
  final TextEditingController _sendController = TextEditingController();
  late FocusNode _focusNode;
  bool _canSend = false;
  bool _previousHexMode = false;

  int _historyIndex = -1;
  String _tempInput = '';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    _sendController.text = ref.read(autoSendDraftProvider);
    _previousHexMode = ref.read(uiControllerProvider).hexSend;
    _updateCanSend(_sendController.text);
  }

  @override
  void dispose() {
    _sendController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setDraft(String value) {
    ref.read(autoSendDraftProvider.notifier).setDraft(value);
    final core = ref.read(uiControllerProvider);
    if (core.autoSendEnabled && value != core.autoSendInput) {
      ref.read(uiControllerProvider.notifier).setAutoSendInput(value);
    }
  }

  void _setDraftAfterFrame(String value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setDraft(value);
    });
  }

  void _navigateHistory(bool up) {
    final history = ref.read(uiControllerProvider).sendHistory;
    if (history.isEmpty) return;
    setState(() {
      if (up) {
        if (_historyIndex == -1) {
          _tempInput = _sendController.text;
          _historyIndex = history.length - 1;
        } else if (_historyIndex > 0) {
          _historyIndex--;
        }
      } else if (_historyIndex != -1) {
        _historyIndex = _historyIndex < history.length - 1
            ? _historyIndex + 1
            : -1;
      }
      final newText = _historyIndex == -1 ? _tempInput : history[_historyIndex];
      _sendController.text = newText;
      _sendController.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
      _updateCanSend(newText);
      _setDraft(newText);
    });
  }

  void _updateCanSend(String value) {
    if (!ref.read(uiControllerProvider).hexSend) {
      _canSend = value.isNotEmpty;
      return;
    }

    if (value.isEmpty) {
      _canSend = false;
      return;
    }

    final sanitized = _sanitizeHex(value);
    if (sanitized.isEmpty) {
      _canSend = false;
    } else {
      _canSend = _isValidHex(sanitized);
    }
  }

  static final RegExp hexRegex = RegExp(r'^[0-9a-fA-F]+$');
  static final RegExp whitespaceRegex = RegExp(r'[ \t\n\r\f]+');

  String _sanitizeHex(String value) => value.replaceAll(whitespaceRegex, '');

  bool _isValidHex(String sanitized) =>
      hexRegex.hasMatch(sanitized) && sanitized.length % 2 == 0;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final text = _sendController.text;
      final selection = _sendController.selection;
      if (selection.isCollapsed && selection.baseOffset >= 0) {
        final textBefore = text.substring(0, selection.baseOffset);
        if (!textBefore.contains('\n')) {
          _navigateHistory(true);
          return KeyEventResult.handled;
        }
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final text = _sendController.text;
      final selection = _sendController.selection;
      if (selection.isCollapsed && selection.baseOffset >= 0) {
        final textAfter = text.substring(selection.baseOffset);
        if (!textAfter.contains('\n')) {
          _navigateHistory(false);
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  String? _hexError(bool hexSend, String value, AppLocalizations l10n) {
    if (!hexSend || value.isEmpty) return null;
    final sanitized = _sanitizeHex(value);
    if (sanitized.isEmpty) return null;
    if (!hexRegex.hasMatch(sanitized)) return l10n.invalidHexChars;
    if (sanitized.length % 2 != 0) return l10n.hexEvenLength;
    return null;
  }

  Widget _buildTextField(bool hexSend, AppLocalizations l10n) {
    return AppInput(
      controller: _sendController,
      focusNode: _focusNode,
      style: const TextStyle(fontFamily: 'monospace'),
      placeholder: l10n.enterDataToSend,
      semanticLabel: l10n.enterDataToSend,
      errorText: _hexError(hexSend, _sendController.text, l10n),
      keyboardType: TextInputType.multiline,
      minLines: 1,
      maxLines: 5,
      onChanged: (value) {
        setState(() {
          _updateCanSend(value);
          final history = ref.read(uiControllerProvider).sendHistory;
          if (_historyIndex != -1 &&
              (_historyIndex >= history.length ||
                  value != history[_historyIndex])) {
            _historyIndex = -1;
          }
        });
        _setDraft(value);
      },
    );
  }

  Widget _buildSendButton(
    UiConnection connectionState,
    bool canSend, {
    required bool compact,
  }) {
    final label = AppLocalizations.of(context).send;
    return AppTooltip(
      message: label,
      child: ShadButton(
        key: const ValueKey('send-button'),
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
        onPressed: connectionState == UiConnection.connected && canSend
            ? () {
                final text = _sendController.text;
                ref.read(uiControllerProvider.notifier).send(text);
                setState(() {
                  _historyIndex = -1;
                  _tempInput = '';
                });
              }
            : null,
        leading: const Icon(LucideIcons.send, size: 16),
        child: compact ? null : Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      uiControllerProvider.select(
        (state) => (connection: state.connection, hexSend: state.hexSend),
      ),
    );
    final connectionState = state.connection;
    final hexSend = state.hexSend;
    if (_previousHexMode != hexSend) {
      _sendController.text = ref.read(uiControllerProvider).autoSendInput;
      _sendController.selection = TextSelection.collapsed(
        offset: _sendController.text.length,
      );
      _updateCanSend(_sendController.text);
      _setDraftAfterFrame(_sendController.text);
      _previousHexMode = hexSend;
    }
    return AppPanel(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final input = _buildTextField(
              hexSend,
              AppLocalizations.of(context),
            );
            final send = _buildSendButton(
              connectionState,
              _canSend,
              compact: constraints.maxWidth < 400,
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: input),
                const SizedBox(width: 8),
                send,
              ],
            );
          },
        ),
      ),
    );
  }
}
