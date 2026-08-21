import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';
import 'package:universal_web/web.dart' as web;

import '../core/stream_channel.dart';

/// A single-line composer that sends messages to the surrounding [StreamChannel].
///
/// This is the minimal counterpart of `StreamMessageComposer` in the Flutter
/// SDK: plain text only. Attachments, mentions, slash commands, polls, voice
/// recording, quoted replies, and edit mode are all absent.
///
/// The field is controlled — Jaspr syncs `value` onto the DOM node and only
/// writes when it differs, so the caret is preserved while typing.
class StreamMessageInput extends StatefulComponent {
  /// Creates a message composer.
  const StreamMessageInput({
    this.placeholder = 'Send a message',
    this.sendTypingEvents = true,
    this.onMessageSent,
    this.onError,
    super.key,
  });

  /// Placeholder shown while the field is empty.
  final String placeholder;

  /// Whether to emit `typing.start` / `typing.stop` events while composing.
  final bool sendTypingEvents;

  /// Called after a message has been accepted by the API.
  final void Function(Message message)? onMessageSent;

  /// Called when sending fails.
  final void Function(Object error)? onError;

  @override
  State<StreamMessageInput> createState() => _StreamMessageInputState();
}

class _StreamMessageInputState extends State<StreamMessageInput> {
  String _text = '';
  bool _isSending = false;

  Channel get _channel => StreamChannel.of(context).channel;

  bool get _canSend => _text.trim().isNotEmpty && !_isSending;

  void _onInput(String value) {
    setState(() => _text = value);
    if (component.sendTypingEvents && value.isNotEmpty) {
      // The low level client throttles these internally, so calling on every
      // keystroke is fine.
      unawaited(_channel.keyStroke().catchError((_) {}));
    }
  }

  void _onKeyDown(web.Event event) {
    final keyEvent = event as web.KeyboardEvent;
    // Shift+Enter is left alone so it stays available for a future multiline
    // composer.
    if (keyEvent.key == 'Enter' && !keyEvent.shiftKey) {
      keyEvent.preventDefault();
      unawaited(_send());
    }
  }

  Future<void> _send() async {
    final text = _text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final response = await _channel.sendMessage(Message(text: text));
      if (!mounted) return;
      setState(() => _text = '');
      component.onMessageSent?.call(response.message);
      if (component.sendTypingEvents) {
        unawaited(_channel.stopTyping().catchError((_) {}));
      }
    } catch (error) {
      if (!mounted) return;
      component.onError?.call(error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Component build(BuildContext context) {
    final canSend = _canSend;

    return div(
      [
        input(
          type: InputType.text,
          value: _text,
          disabled: _isSending,
          classes: 'sc-composer__input',
          attributes: {
            'placeholder': component.placeholder,
            'aria-label': component.placeholder,
            'autocomplete': 'off',
          },
          onInput: _onInput,
          events: {'keydown': _onKeyDown},
        ),
        button(
          [_sendIcon()],
          type: ButtonType.button,
          disabled: !canSend,
          classes: 'sc-composer__send',
          attributes: {'aria-label': 'Send message'},
          onClick: () => unawaited(_send()),
        ),
      ],
      classes: 'sc-composer',
    );
  }

  Component _sendIcon() {
    return svg(
      [
        path(
          [],
          d: 'M2 21l21-9L2 3v7l15 2-15 2v7z',
          fill: Color.currentColor,
        ),
      ],
      viewBox: '0 0 24 24',
      attributes: {'aria-hidden': 'true'},
    );
  }
}
