import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../util/formatting.dart';
import 'stream_avatar.dart';

/// Emoji shown for each of Stream's default reaction types.
///
/// Unknown types fall through to the raw type string, so custom reactions
/// still render something rather than disappearing.
const Map<String, String> defaultReactionEmoji = {
  'like': '\u{1F44D}',
  'love': '\u{2764}\u{FE0F}',
  'haha': '\u{1F602}',
  'wow': '\u{1F62E}',
  'sad': '\u{1F622}',
  'angry': '\u{1F621}',
};

/// Renders a single message: avatar, author line, bubble, and reactions.
///
/// Consecutive messages from the same author are visually grouped by the
/// parent list, which passes `showAvatar: false` / `showAuthor: false` for
/// every message after the first in a run.
class StreamMessageTile extends StatelessComponent {
  /// Creates a message tile.
  const StreamMessageTile({
    required this.message,
    required this.isOwn,
    this.showAvatar = true,
    this.showAuthor = true,
    this.onReactionTap,
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

  /// Called when an existing reaction chip is activated.
  final void Function(Message message, String reactionType)? onReactionTap;

  @override
  Component build(BuildContext context) {
    final user = message.user;

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
            if (showAuthor) _meta(),
            _bubble(),
            ..._reactions(),
          ],
          classes: 'sc-message-group__stack',
        ),
      ],
      classes: 'sc-message-group${isOwn ? ' sc-message-group--own' : ''}',
    );
  }

  Component _meta() {
    final authorName = isOwn ? null : message.user?.name;
    return div(
      [
        if (authorName != null)
          span(
            [Component.text(authorName)],
            classes: 'sc-message-meta__author',
          ),
        span([Component.text(formatTimeOfDay(message.createdAt))]),
      ],
      classes: 'sc-message-meta',
    );
  }

  Component _bubble() {
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
        [Component.text('This message was deleted')],
        classes: 'sc-bubble$modifier',
      );
    }

    final text = message.text ?? '';
    final attachments = message.attachments;

    return div(
      [
        if (text.isNotEmpty) Component.text(text),
        if (attachments.isNotEmpty)
          div(
            [for (final attachment in attachments) _attachment(attachment)],
            classes: 'sc-bubble__attachments',
          ),
      ],
      classes:
          'sc-bubble${isOwn ? ' sc-bubble--own' : ''}$modifier',
    );
  }

  Component _attachment(Attachment attachment) {
    final imageUrl = attachment.imageUrl ?? attachment.thumbUrl;
    if (attachment.type == AttachmentType.image && imageUrl != null) {
      return img(
        src: imageUrl,
        alt: attachment.title ?? 'Image attachment',
        classes: 'sc-attachment-image',
      );
    }

    final url = attachment.assetUrl ?? attachment.titleLink ?? imageUrl;
    final title = attachment.title ?? attachment.fallback ?? 'Attachment';
    if (url == null) {
      return div([Component.text(title)], classes: 'sc-attachment-file');
    }

    return a(
      [Component.text(title)],
      href: url,
      target: Target.blank,
      classes: 'sc-attachment-file',
      attributes: {'rel': 'noopener noreferrer'},
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
              button(
                [
                  Component.text(defaultReactionEmoji[type] ?? type),
                  Component.text('${group.count}'),
                ],
                classes:
                    'sc-reaction${own.contains(type) ? ' sc-reaction--own' : ''}',
                onClick: () => onReactionTap?.call(message, type),
              ),
        ],
        classes: 'sc-reactions',
      ),
    ];
  }
}
