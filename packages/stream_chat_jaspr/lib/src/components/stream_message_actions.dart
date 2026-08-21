import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../core/stream_channel.dart';
import '../core/stream_chat.dart';
import '../core/stream_message_composer_controller.dart';
import '../i18n/stream_chat_translations.dart';
import '../util/dom.dart';
import '../util/icons.dart';
import 'stream_popover.dart';
import 'stream_reaction_picker.dart';

/// The controls that appear on a message while the pointer is over it.
///
/// Renders a compact toolbar of the two most used actions, reacting and
/// replying in a thread, and puts the rest behind an overflow menu. That
/// mirrors how the Flutter SDK splits `StreamReactionPicker` from the long
/// press action sheet, adapted to a pointer-driven surface where hover is
/// available and a bottom sheet would be out of place.
///
/// The component performs the actions itself rather than reporting them
/// upwards, because every one of them is a direct call on the channel or the
/// composer, both of which it can reach through the surrounding scopes.
class StreamMessageActions extends StatefulComponent {
  /// Creates the action toolbar for [message].
  const StreamMessageActions({
    required this.message,
    required this.isOwn,
    this.showThreadAction = true,
    super.key,
  });

  /// The message the actions apply to.
  final Message message;

  /// Whether [message] was sent by the connected user, which decides whether
  /// editing and deleting are offered.
  final bool isOwn;

  /// Whether to offer opening a thread. Suppressed inside a thread, where
  /// replies cannot themselves be threaded.
  final bool showThreadAction;

  @override
  State<StreamMessageActions> createState() => _StreamMessageActionsState();
}

enum _OpenOverlay { none, reactions, menu, deleteConfirm }

class _StreamMessageActionsState extends State<StreamMessageActions> {
  _OpenOverlay _open = _OpenOverlay.none;
  String? _notice;

  Channel get _channel => StreamChannel.of(context).channel;

  StreamChatTranslations get _text => StreamChat.translationsOf(context);

  void _close() => setState(() => _open = _OpenOverlay.none);

  void _toggle(_OpenOverlay overlay) {
    setState(() => _open = _open == overlay ? _OpenOverlay.none : overlay);
  }

  Future<void> _toggleReaction(String type) async {
    _close();
    final message = component.message;
    final own = message.ownReactions?.map((it) => it.type).toSet() ?? {};

    try {
      if (own.contains(type)) {
        await _channel.deleteReaction(message, Reaction(type: type));
      } else {
        // Stream allows several reactions per user per message. Sending
        // without `enforceUnique` matches the Flutter SDK, where picking a
        // second emoji adds it rather than replacing the first.
        await _channel.sendReaction(message, Reaction(type: type));
      }
    } catch (_) {
      _notify(_text.actionFailed(_text.addReactionLabel));
    }
  }

  Future<void> _copy() async {
    _close();
    final copied = await copyToClipboard(component.message.text ?? '');
    if (!copied) _notify(_text.copyFailed);
  }

  Future<void> _togglePin() async {
    _close();
    final message = component.message;
    final label = message.pinned ? _text.unpinMessage : _text.pinMessage;
    try {
      if (message.pinned) {
        await _channel.unpinMessage(message);
      } else {
        await _channel.pinMessage(message);
      }
    } catch (_) {
      _notify(_text.actionFailed(label));
    }
  }

  Future<void> _flag() async {
    _close();
    try {
      await StreamChat.of(context).client.flagMessage(component.message.id);
      _notify(_text.messageFlagged);
    } catch (_) {
      _notify(_text.actionFailed(_text.flagMessage));
    }
  }

  Future<void> _delete() async {
    _close();
    try {
      await _channel.deleteMessage(component.message);
    } catch (_) {
      _notify(_text.actionFailed(_text.deleteMessage));
    }
  }

  Future<void> _resend() async {
    _close();
    try {
      await _channel.sendMessage(component.message);
    } catch (_) {
      _notify(_text.actionFailed(_text.retry));
    }
  }

  void _quote() {
    _close();
    StreamMessageComposerController.of(context).quote(component.message);
  }

  void _edit() {
    _close();
    StreamMessageComposerController.of(context).edit(component.message);
  }

  void _openThread() {
    _close();
    StreamChannel.of(context).openThreadFor(component.message);
  }

  /// Shows a transient message under the toolbar.
  ///
  /// Used for outcomes that have no visible effect on the message itself, such
  /// as flagging, and for failures.
  void _notify(String message) {
    if (!mounted) return;
    setState(() => _notice = message);
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  @override
  Component build(BuildContext context) {
    final translations = _text;
    final message = component.message;
    final canEdit = component.isOwn && !message.isDeleted;

    return div(
      [
        div(
          [
            _toolbarButton(
              icon: StreamIcons.smile(),
              label: translations.addReactionLabel,
              expanded: _open == _OpenOverlay.reactions,
              onPressed: () => _toggle(_OpenOverlay.reactions),
            ),
            if (component.showThreadAction)
              _toolbarButton(
                icon: StreamIcons.thread(),
                label: translations.replyInThread,
                onPressed: _openThread,
              ),
            _toolbarButton(
              icon: StreamIcons.more(),
              label: translations.messageActionsLabel,
              expanded: _open == _OpenOverlay.menu,
              onPressed: () => _toggle(_OpenOverlay.menu),
            ),
          ],
          classes: 'sc-message-actions__bar',
        ),
        if (_open == _OpenOverlay.reactions)
          StreamPopover(
            label: translations.addReactionLabel,
            role: 'dialog',
            classes: 'sc-popover--reactions',
            onDismiss: _close,
            children: [
              StreamReactionPicker(
                ownReactions:
                    message.ownReactions?.map((it) => it.type).toSet() ?? {},
                onSelected: (type) => unawaited(_toggleReaction(type)),
              ),
            ],
          ),
        if (_open == _OpenOverlay.menu)
          StreamPopover(
            label: translations.messageActionsLabel,
            onDismiss: _close,
            children: [
              if (message.state.isFailed)
                _menuItem(
                  icon: StreamIcons.alert(),
                  label: translations.retry,
                  onPressed: () => unawaited(_resend()),
                ),
              if (component.showThreadAction)
                _menuItem(
                  icon: StreamIcons.thread(),
                  label: translations.replyInThread,
                  onPressed: _openThread,
                ),
              _menuItem(
                icon: StreamIcons.reply(),
                label: translations.quoteMessage,
                onPressed: _quote,
              ),
              if ((message.text ?? '').isNotEmpty)
                _menuItem(
                  icon: StreamIcons.copy(),
                  label: translations.copyText,
                  onPressed: () => unawaited(_copy()),
                ),
              _menuItem(
                icon: StreamIcons.pin(),
                label: message.pinned
                    ? translations.unpinMessage
                    : translations.pinMessage,
                onPressed: () => unawaited(_togglePin()),
              ),
              if (canEdit)
                _menuItem(
                  icon: StreamIcons.pencil(),
                  label: translations.editMessage,
                  onPressed: _edit,
                ),
              if (!component.isOwn)
                _menuItem(
                  icon: StreamIcons.flag(),
                  label: translations.flagMessage,
                  onPressed: () => unawaited(_flag()),
                ),
              if (component.isOwn && !message.isDeleted)
                _menuItem(
                  icon: StreamIcons.trash(),
                  label: translations.deleteMessage,
                  danger: true,
                  onPressed: () =>
                      setState(() => _open = _OpenOverlay.deleteConfirm),
                ),
            ],
          ),
        if (_open == _OpenOverlay.deleteConfirm) _deleteConfirmation(),
        if (_notice case final notice?)
          div(
            [Component.text(notice)],
            classes: 'sc-message-actions__notice',
            attributes: const {'role': 'status'},
          ),
      ],
      classes: 'sc-message-actions sc-popover-anchor',
    );
  }

  Component _toolbarButton({
    required Component icon,
    required String label,
    required void Function() onPressed,
    bool expanded = false,
  }) {
    return button(
      [icon],
      type: ButtonType.button,
      classes: 'sc-message-actions__button',
      attributes: {
        'aria-label': label,
        'title': label,
        'aria-haspopup': 'true',
        'aria-expanded': '$expanded',
      },
      onClick: onPressed,
    );
  }

  Component _menuItem({
    required Component icon,
    required String label,
    required void Function() onPressed,
    bool danger = false,
  }) {
    return button(
      [icon, span([Component.text(label)])],
      type: ButtonType.button,
      classes: danger ? 'sc-menu-item sc-menu-item--danger' : 'sc-menu-item',
      attributes: const {'role': 'menuitem'},
      onClick: onPressed,
    );
  }

  Component _deleteConfirmation() {
    final translations = _text;

    return StreamPopover(
      role: 'dialog',
      label: translations.deleteMessage,
      classes: 'sc-popover--confirm',
      onDismiss: _close,
      children: [
        p([Component.text(translations.deleteMessageConfirmation)]),
        div(
          [
            button(
              [Component.text(translations.cancel)],
              type: ButtonType.button,
              classes: 'sc-button sc-button--ghost',
              onClick: _close,
            ),
            button(
              [Component.text(translations.confirm)],
              type: ButtonType.button,
              classes: 'sc-button sc-button--danger',
              onClick: () => unawaited(_delete()),
            ),
          ],
          classes: 'sc-popover__actions',
        ),
      ],
    );
  }
}
