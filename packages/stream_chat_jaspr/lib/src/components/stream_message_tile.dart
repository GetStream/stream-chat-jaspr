import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../core/stream_channel.dart';
import '../core/stream_chat.dart';
import '../i18n/stream_chat_translations.dart';
import '../util/formatting.dart';
import '../util/icons.dart';
import '../util/message_text.dart';
import 'stream_attachment_list.dart';
import 'stream_avatar.dart';
import 'stream_message_actions.dart';
import 'stream_reaction_picker.dart';

/// Renders a single message: avatar, author line, bubble, attachments,
/// reactions, and the controls that act on it.
///
/// Consecutive messages from the same author are visually grouped by the
/// parent list, which passes `showAvatar: false` and `showAuthor: false` for
/// every message after the first in a run.
class StreamMessageTile extends StatelessComponent {
  /// Creates a message tile.
  const StreamMessageTile({
    required this.message,
    required this.isOwn,
    this.showAvatar = true,
    this.showAuthor = true,
    this.showActions = true,
    this.showThreadFooter = true,
    this.showDeliveryState = false,
    this.readBy = const [],
    this.highlighted = false,
    this.onQuotedMessageTap,
    super.key,
  });

  /// The message to render.
  final Message message;

  /// Whether the message was sent by the connected user.
  final bool isOwn;

  /// Whether to render the author's avatar next to the bubble.
  final bool showAvatar;

  /// Whether to render the author name and timestamp above the bubble.
  final bool showAuthor;

  /// Whether to offer reactions and the action menu on hover.
  final bool showActions;

  /// Whether to render the reply count that opens the thread.
  ///
  /// Suppressed inside a thread, where the replies are already on screen.
  final bool showThreadFooter;

  /// Whether to render the sending or read indicator under the bubble.
  ///
  /// The list sets this only on the newest own message, matching the
  /// convention in the Flutter SDK and in most chat products, where a column
  /// of identical ticks adds nothing.
  final bool showDeliveryState;

  /// Users who have read this message, excluding its author.
  final List<User> readBy;

  /// Whether to draw attention to this message, used when jumping to a search
  /// result.
  final bool highlighted;

  /// Called when the quoted message preview is activated.
  final void Function(Message quoted)? onQuotedMessageTap;

  @override
  Component build(BuildContext context) {
    final translations = StreamChat.translationsOf(context);
    final user = message.user;

    final classes = [
      'sc-message-group',
      if (isOwn) 'sc-message-group--own',
      if (highlighted) 'sc-message-group--highlighted',
    ].join(' ');

    return div(
      [
        // Own messages are already identified by side and colour, so the
        // avatar would only add noise. Incoming runs keep a spacer so grouped
        // bubbles stay aligned under the first one.
        if (!isOwn)
          if (showAvatar && user != null)
            StreamAvatar.user(user, size: 32)
          else
            div([], classes: 'sc-message-group__spacer'),
        div(
          [
            if (message.pinned) _pinnedMarker(translations),
            if (showAuthor) _meta(translations),
            div(
              [
                _bubble(translations),
                if (showActions && !message.isDeleted)
                  StreamMessageActions(
                    message: message,
                    isOwn: isOwn,
                    showThreadAction: showThreadFooter,
                  ),
              ],
              classes: 'sc-message-group__row',
            ),
            ..._reactions(),
            if (showThreadFooter && (message.replyCount ?? 0) > 0)
              _threadFooter(context, translations),
            if (showDeliveryState) _deliveryState(translations),
          ],
          classes: 'sc-message-group__stack',
        ),
      ],
      classes: classes,
      attributes: {'data-message-id': message.id},
    );
  }

  Component _pinnedMarker(StreamChatTranslations translations) {
    final by = message.pinnedBy?.name;
    return div(
      [
        StreamIcons.pin(),
        span([
          Component.text(
            by == null ? translations.pinMessage : translations.pinnedBy(by),
          ),
        ]),
      ],
      classes: 'sc-message-pinned',
    );
  }

  Component _meta(StreamChatTranslations translations) {
    final authorName = isOwn ? null : message.user?.name;
    return div(
      [
        if (authorName != null)
          span(
            [Component.text(authorName)],
            classes: 'sc-message-meta__author',
          ),
        span([Component.text(formatTimeOfDay(message.createdAt))]),
        if (message.messageTextUpdatedAt != null)
          span(
            [Component.text(translations.edited)],
            classes: 'sc-message-meta__edited',
          ),
      ],
      classes: 'sc-message-meta',
    );
  }

  Component _bubble(StreamChatTranslations translations) {
    final state = message.state;
    final isDeleted = message.isDeleted || state.isDeleted;

    final modifier = switch (state) {
      _ when isDeleted => ' sc-bubble--deleted',
      _ when state.isFailed => ' sc-bubble--failed',
      _ when state.isOutgoing => ' sc-bubble--pending',
      _ => '',
    };

    if (isDeleted) {
      return div(
        [Component.text(translations.messageDeleted)],
        classes: 'sc-bubble$modifier',
      );
    }

    final text = message.text ?? '';
    final quoted = message.quotedMessage;

    // A message that is nothing but attachments gets no bubble. A coloured
    // frame around a photo adds nothing and makes the image look inset.
    final isBare =
        text.isEmpty && quoted == null && message.attachments.isNotEmpty;

    return div(
      [
        if (quoted != null) _quotedPreview(quoted, translations),
        if (text.isNotEmpty)
          div(_textSpans(text), classes: 'sc-bubble__text'),
        if (message.attachments.isNotEmpty)
          StreamAttachmentList(attachments: message.attachments),
      ],
      classes: 'sc-bubble'
          '${isOwn ? ' sc-bubble--own' : ''}'
          '${isBare ? ' sc-bubble--bare' : ''}'
          '$modifier',
    );
  }

  /// Renders message text with links, mentions, and inline code marked up.
  List<Component> _textSpans(String text) {
    final mentioned = {
      for (final user in message.mentionedUsers) ...[
        user.name,
        user.id,
      ],
    };

    return [
      for (final token in tokenizeMessageText(text, mentionedNames: mentioned))
        switch (token.kind) {
          MessageTokenKind.text => Component.text(token.value),
          MessageTokenKind.code =>
            code([Component.text(token.value)], classes: 'sc-code'),
          MessageTokenKind.mention => span(
              [Component.text('@${token.value}')],
              classes: 'sc-mention',
            ),
          MessageTokenKind.link => a(
              [Component.text(token.value)],
              href: token.value,
              target: Target.blank,
              classes: 'sc-link',
              attributes: const {'rel': 'noopener noreferrer'},
            ),
        },
    ];
  }

  Component _quotedPreview(Message quoted, StreamChatTranslations translations) {
    final author = quoted.user?.name;
    final text = quoted.isDeleted
        ? translations.messageDeleted
        : (quoted.text ?? '').isNotEmpty
            ? quoted.text!
            : translations.attachment;

    return button(
      [
        if (author != null)
          span([Component.text(author)], classes: 'sc-quoted__author'),
        span([Component.text(text)], classes: 'sc-quoted__text'),
      ],
      type: ButtonType.button,
      classes: 'sc-quoted',
      attributes: {'aria-label': '${translations.quoteMessage}: $text'},
      onClick: () => onQuotedMessageTap?.call(quoted),
    );
  }

  List<Component> _reactions() {
    final groups = message.reactionGroups;
    if (groups == null || groups.isEmpty) return const [];

    final own = {...?message.ownReactions?.map((it) => it.type)};
    final sorted = groups.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));

    return [
      div(
        [
          for (final MapEntry(key: type, value: group) in sorted)
            if (group.count > 0)
              _ReactionChip(
                message: message,
                type: type,
                count: group.count,
                isOwn: own.contains(type),
              ),
        ],
        classes: 'sc-reactions',
      ),
    ];
  }

  Component _threadFooter(
    BuildContext context,
    StreamChatTranslations translations,
  ) {
    final count = message.replyCount ?? 0;
    return button(
      [
        StreamIcons.thread(),
        Component.text(translations.replyCount(count)),
      ],
      type: ButtonType.button,
      classes: 'sc-thread-footer',
      onClick: () => StreamChannel.maybeOf(context)?.openThreadFor(message),
    );
  }

  Component _deliveryState(StreamChatTranslations translations) {
    final state = message.state;

    final (icon, label) = switch (state) {
      _ when state.isFailed => (StreamIcons.alert(), translations.messageFailed),
      _ when state.isOutgoing => (StreamIcons.clock(), translations.sendingLabel),
      _ when readBy.isNotEmpty => (
          StreamIcons.checkAll(),
          translations.readBy([for (final user in readBy) user.name]),
        ),
      _ => (StreamIcons.check(), translations.deliveredLabel),
    };

    return div(
      [
        icon,
        span([Component.text(label)]),
      ],
      classes: state.isFailed
          ? 'sc-delivery sc-delivery--failed'
          : 'sc-delivery',
      attributes: const {'aria-live': 'polite'},
    );
  }
}

/// A single reaction chip, which toggles the current user's reaction.
///
/// Split out so that the tile itself can stay stateless: only the chip needs
/// to talk to the channel.
class _ReactionChip extends StatelessComponent {
  const _ReactionChip({
    required this.message,
    required this.type,
    required this.count,
    required this.isOwn,
  });

  final Message message;
  final String type;
  final int count;
  final bool isOwn;

  @override
  Component build(BuildContext context) {
    return button(
      [
        Component.text(defaultReactionEmoji[type] ?? type),
        Component.text('$count'),
      ],
      type: ButtonType.button,
      classes: isOwn ? 'sc-reaction sc-reaction--own' : 'sc-reaction',
      attributes: {
        'aria-label': '$type $count',
        'aria-pressed': '$isOwn',
        'title': type,
      },
      onClick: () {
        // Resolved on activation rather than during build so that a tile can
        // be rendered outside a channel scope, which is what the component
        // tests do.
        final channel = StreamChannel.maybeOf(context)?.channel;
        if (channel == null) return;

        final reaction = Reaction(type: type);
        final future = isOwn
            ? channel.deleteReaction(message, reaction)
            : channel.sendReaction(message, reaction);
        // A failure here is already reflected in the UI, because the client
        // rolls its optimistic update back when the request fails.
        future.ignore();
      },
    );
  }
}
