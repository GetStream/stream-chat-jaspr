import 'dart:async';

import 'package:collection/collection.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';
import 'package:universal_web/web.dart' as web;

import '../core/stream_channel.dart';
import '../core/stream_chat.dart';
import '../i18n/stream_chat_translations.dart';
import '../util/formatting.dart';
import '../util/icons.dart';
import 'stream_message_tile.dart';

/// A scrollable list of the messages in the surrounding [StreamChannel].
///
/// The container is laid out with `flex-direction: column-reverse`, which is
/// what keeps the newest message in view. In a reversed flex container the
/// browser anchors scrolling to the visual bottom, so appending a message
/// keeps the viewport pinned without any imperative scrolling, and a user who
/// has scrolled up stays where they are. The cost is that children must be
/// emitted newest-first, which is why the visual list is built in natural
/// order and reversed at the end.
///
/// Pass [parentId] to render a thread instead of the main conversation.
class StreamMessageListView extends StatefulComponent {
  /// Creates a message list.
  const StreamMessageListView({
    this.parentId,
    this.pageSize = 25,
    this.groupWindow = const Duration(minutes: 5),
    this.markReadOnView = true,
    this.showDeliveryState = true,
    this.highlightedMessageId,
    this.empty,
    super.key,
  });

  /// When set, the list renders the replies to this message rather than the
  /// channel's own messages.
  final String? parentId;

  /// How many older messages to fetch per page.
  final int pageSize;

  /// Consecutive messages from one author within this window are grouped
  /// under a single avatar and author line.
  final Duration groupWindow;

  /// Whether to mark the channel read as messages come into view.
  final bool markReadOnView;

  /// Whether to show the sending and read indicator on the newest own message.
  final bool showDeliveryState;

  /// A message to draw attention to, used when jumping to a search result.
  final String? highlightedMessageId;

  /// Rendered when the channel has no messages.
  final Component? empty;

  @override
  State<StreamMessageListView> createState() => _StreamMessageListViewState();
}

class _StreamMessageListViewState extends State<StreamMessageListView> {
  /// Distance from the top, in pixels, at which older messages are requested.
  static const _loadMoreThreshold = 250;

  /// How far the user has to scroll up before the jump-to-latest button shows.
  static const _jumpButtonThreshold = 400;

  bool _isLoadingMore = false;
  bool _reachedStart = false;
  bool _isScrolledUp = false;
  String? _lastMarkedReadId;
  web.Element? _viewport;

  Channel get _channel => StreamChannel.of(context).channel;

  bool get _isThread => component.parentId != null;

  Future<void> _loadOlder(List<Message> messages) async {
    if (_isLoadingMore || _reachedStart) return;
    final oldest = messages.firstOrNull;
    if (oldest == null) return;

    _isLoadingMore = true;
    try {
      final pagination = PaginationParams(
        limit: component.pageSize,
        lessThan: oldest.id,
      );

      final fetched = switch (component.parentId) {
        final parentId? => (await _channel.getReplies(
            parentId,
            options: pagination,
          ))
            .messages
            .length,
        _ => (await _channel.query(messagesPagination: pagination))
                .messages
                ?.length ??
            0,
      };

      if (fetched < component.pageSize) _reachedStart = true;
    } catch (_) {
      // Leave pagination enabled so a transient failure can be retried by
      // simply scrolling again.
    } finally {
      _isLoadingMore = false;
    }
  }

  void _onScroll(web.Event event) {
    // Interop types are erased, so `is` checks against them are meaningless.
    // The target of a scroll event is always the element the handler is bound
    // to, which makes the cast safe.
    final target = event.target as web.Element?;
    if (target == null) return;
    _viewport = target;

    // In a column-reverse container browsers report scrollTop as 0 at the
    // visual bottom and grow it (negatively in some engines) towards the top,
    // so compare on magnitude rather than sign.
    final offset = target.scrollTop.abs();
    final distanceFromTop = target.scrollHeight - offset - target.clientHeight;
    if (distanceFromTop <= _loadMoreThreshold) {
      unawaited(_loadOlder(_messagesFor(_channel)));
    }

    final isScrolledUp = offset > _jumpButtonThreshold;
    if (isScrolledUp != _isScrolledUp) {
      setState(() => _isScrolledUp = isScrolledUp);
    }
  }

  void _jumpToLatest() {
    // Zero is the visual bottom in a reversed container, in both the engines
    // that keep scrollTop positive and those that count it down from zero.
    _viewport?.scrollTop = 0;
    setState(() => _isScrolledUp = false);
  }

  void _maybeMarkRead(List<Message> messages) {
    // Marking a thread read is a separate concept in the API and is not
    // driven by scrolling the reply list.
    if (!component.markReadOnView || _isThread) return;
    final channel = _channel;
    if ((channel.state?.unreadCount ?? 0) == 0) return;

    final newest = messages.lastOrNull;
    if (newest == null || newest.id == _lastMarkedReadId) return;
    _lastMarkedReadId = newest.id;
    unawaited(channel.markRead());
  }

  List<Message> _messagesFor(Channel channel) {
    final parentId = component.parentId;
    if (parentId == null) return channel.state?.messages ?? const [];
    return channel.state?.threads[parentId] ?? const [];
  }

  /// Users, other than the author, whose read cursor is at or past [message].
  List<User> _readersOf(Message message, String? currentUserId) {
    final reads = _channel.state?.read ?? const <Read>[];
    return [
      for (final read in reads)
        if (read.user.id != currentUserId &&
            read.user.id != message.user?.id &&
            !read.lastRead.isBefore(message.createdAt))
          read.user,
    ];
  }

  @override
  Component build(BuildContext context) {
    final channel = _channel;
    final currentUserId = StreamChat.of(context).currentUser?.id;
    final translations = StreamChat.translationsOf(context);
    final parentId = component.parentId;

    return StreamBuilder<List<Message>>(
      stream: parentId == null
          ? channel.state?.messagesStream
          : channel.state?.threadsStream
              .map((threads) => threads[parentId] ?? const <Message>[]),
      initialData: _messagesFor(channel),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <Message>[];
        if (messages.isEmpty && !_isThread) {
          return component.empty ??
              div(
                [Component.text(translations.noMessagesYet)],
                classes: 'sc-empty',
              );
        }

        _maybeMarkRead(messages);

        return div(
          [
            div(
              _buildChildren(messages, currentUserId, translations),
              classes: 'sc-message-list',
              events: {'scroll': _onScroll},
            ),
            if (_isScrolledUp)
              button(
                [StreamIcons.arrowDown()],
                type: ButtonType.button,
                classes: 'sc-jump-to-latest',
                attributes: {'aria-label': translations.jumpToLatest},
                onClick: _jumpToLatest,
              ),
          ],
          classes: 'sc-message-list-wrap',
        );
      },
    );
  }

  List<Component> _buildChildren(
    List<Message> messages,
    String? currentUserId,
    StreamChatTranslations translations,
  ) {
    final visual = <Component>[];

    // The delivery indicator only goes on the newest own message, so find it
    // once rather than asking the question for every tile.
    final lastOwnId = messages.lastWhereOrNull(
      (it) => it.user?.id == currentUserId && !it.isDeleted,
    )?.id;

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final previous = i > 0 ? messages[i - 1] : null;

      final startsNewDay =
          previous == null || !isSameDay(previous.createdAt, message.createdAt);
      if (startsNewDay) {
        visual.add(
          div(
            [
              Component.text(
                formatDateDivider(
                  message.createdAt,
                  today: translations.today,
                  yesterday: translations.yesterday,
                ),
              ),
            ],
            key: ValueKey('divider-${message.id}'),
            classes: 'sc-date-divider',
          ),
        );
      }

      final sameAuthor = previous?.user?.id == message.user?.id;
      final withinWindow = previous != null &&
          message.createdAt.difference(previous.createdAt) <=
              component.groupWindow;
      final startsRun = startsNewDay || !sameAuthor || !withinWindow;
      final isOwn = message.user?.id == currentUserId;
      final showDeliveryState = component.showDeliveryState &&
          isOwn &&
          message.id == lastOwnId;

      visual.add(
        StreamMessageTile(
          key: ValueKey(message.id),
          message: message,
          isOwn: isOwn,
          showAvatar: startsRun,
          showAuthor: startsRun,
          showThreadFooter: !_isThread,
          showDeliveryState: showDeliveryState,
          readBy: showDeliveryState
              ? _readersOf(message, currentUserId)
              : const [],
          highlighted: message.id == component.highlightedMessageId,
        ),
      );
    }

    if (_isThread && messages.isNotEmpty) {
      visual.insert(
        0,
        div(
          [Component.text(translations.startOfThread)],
          classes: 'sc-date-divider',
        ),
      );
    }

    // The container is column-reverse, so DOM order is the inverse of what the
    // reader sees.
    return visual.reversed.toList();
  }
}
