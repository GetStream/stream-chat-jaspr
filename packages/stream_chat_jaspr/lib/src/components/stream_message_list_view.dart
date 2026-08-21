import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';
import 'package:universal_web/web.dart' as web;

import '../core/stream_chat.dart';
import '../core/stream_channel.dart';
import '../util/formatting.dart';
import 'stream_message_tile.dart';

/// A scrollable list of the messages in the surrounding [StreamChannel].
///
/// The container is laid out with `flex-direction: column-reverse`, which is
/// what keeps the newest message in view. In a reversed flex container the
/// browser anchors scrolling to the visual bottom, so appending a message
/// keeps the viewport pinned without any imperative scrolling — and a user who
/// has scrolled up stays where they are. The cost is that children must be
/// emitted newest-first, which is why the visual list is built in natural
/// order and reversed at the end.
class StreamMessageListView extends StatefulComponent {
  /// Creates a message list.
  const StreamMessageListView({
    this.pageSize = 25,
    this.groupWindow = const Duration(minutes: 5),
    this.markReadOnView = true,
    this.empty,
    super.key,
  });

  /// How many older messages to fetch per page.
  final int pageSize;

  /// Consecutive messages from one author within this window are grouped
  /// under a single avatar and author line.
  final Duration groupWindow;

  /// Whether to mark the channel read as messages come into view.
  final bool markReadOnView;

  /// Rendered when the channel has no messages.
  final Component? empty;

  @override
  State<StreamMessageListView> createState() => _StreamMessageListViewState();
}

class _StreamMessageListViewState extends State<StreamMessageListView> {
  /// Distance from the top, in pixels, at which older messages are requested.
  static const _loadMoreThreshold = 250;

  bool _isLoadingMore = false;
  bool _reachedStart = false;
  String? _lastMarkedReadId;

  Channel get _channel => StreamChannel.of(context).channel;

  Future<void> _loadOlder() async {
    if (_isLoadingMore || _reachedStart) return;
    final oldest = _channel.state?.messages.firstOrNull;
    if (oldest == null) return;

    _isLoadingMore = true;
    try {
      final result = await _channel.query(
        messagesPagination: PaginationParams(
          limit: component.pageSize,
          lessThan: oldest.id,
        ),
      );
      final fetched = result.messages?.length ?? 0;
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
    // In a column-reverse container browsers report scrollTop as 0 at the
    // visual bottom and grow it (negatively in some engines) towards the top,
    // so compare on magnitude rather than sign.
    final distanceFromTop = target.scrollHeight -
        target.scrollTop.abs() -
        target.clientHeight;
    if (distanceFromTop <= _loadMoreThreshold) {
      unawaited(_loadOlder());
    }
  }

  void _maybeMarkRead(List<Message> messages) {
    if (!component.markReadOnView) return;
    final channel = _channel;
    if ((channel.state?.unreadCount ?? 0) == 0) return;

    final newest = messages.lastOrNull;
    if (newest == null || newest.id == _lastMarkedReadId) return;
    _lastMarkedReadId = newest.id;
    unawaited(channel.markRead());
  }

  @override
  Component build(BuildContext context) {
    final channel = _channel;
    final currentUserId = StreamChat.of(context).currentUser?.id;

    return StreamBuilder<List<Message>>(
      stream: channel.state?.messagesStream,
      initialData: channel.state?.messages,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <Message>[];
        if (messages.isEmpty) {
          return component.empty ??
              div(
                [Component.text('No messages yet. Say hello.')],
                classes: 'sc-empty',
              );
        }

        _maybeMarkRead(messages);

        return div(
          _buildChildren(messages, currentUserId),
          classes: 'sc-message-list',
          events: {'scroll': _onScroll},
        );
      },
    );
  }

  List<Component> _buildChildren(
    List<Message> messages,
    String? currentUserId,
  ) {
    final visual = <Component>[];

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final previous = i > 0 ? messages[i - 1] : null;

      final startsNewDay =
          previous == null || !isSameDay(previous.createdAt, message.createdAt);
      if (startsNewDay) {
        visual.add(
          div(
            [Component.text(formatDateDivider(message.createdAt))],
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

      visual.add(
        StreamMessageTile(
          key: ValueKey(message.id),
          message: message,
          isOwn: message.user?.id == currentUserId,
          showAvatar: startsRun,
          showAuthor: startsRun,
        ),
      );
    }

    // The container is column-reverse, so DOM order is the inverse of what the
    // reader sees.
    return visual.reversed.toList();
  }
}
