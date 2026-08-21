import 'dart:async';

// `Filter` exists in both jaspr's CSS properties and stream_chat's query API.
// The query one is what this component deals in.
import 'package:jaspr/dom.dart' hide Filter;
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';
import 'package:universal_web/web.dart' as web;

import '../core/stream_chat.dart';
import '../core/stream_channel_list_controller.dart';
import 'stream_channel_list_tile.dart';

/// A scrollable, paginated list of channels.
///
/// Creates and owns a [StreamChannelListController] unless you pass one in.
/// Pagination is driven by the scroll position of the list itself. Jaspr has no
/// `ScrollController` equivalent, so the next page is requested when the
/// container gets within a threshold of its own scroll extent.
class StreamChannelListView extends StatefulComponent {
  /// Creates a channel list.
  const StreamChannelListView({
    this.controller,
    this.filter,
    this.sort,
    this.limit = 20,
    this.selectedChannelCid,
    this.onChannelTap,
    this.empty,
    super.key,
  });

  /// An externally owned controller. When null, one is created internally.
  final StreamChannelListController? controller;

  /// Filter for the internally created controller. Ignored if [controller] is set.
  final Filter? filter;

  /// Sort for the internally created controller. Ignored if [controller] is set.
  final SortOrder<ChannelState>? sort;

  /// Page size for the internally created controller. Ignored if [controller] is set.
  final int limit;

  /// The `cid` of the currently open channel, highlighted in the list.
  final String? selectedChannelCid;

  /// Called when a channel is selected.
  final void Function(Channel channel)? onChannelTap;

  /// Rendered when the query returns no channels.
  final Component? empty;

  @override
  State<StreamChannelListView> createState() => _StreamChannelListViewState();
}

class _StreamChannelListViewState extends State<StreamChannelListView> {
  /// Distance from the bottom, in pixels, at which the next page is requested.
  static const _loadMoreThreshold = 200;

  StreamChannelListController? _internalController;

  StreamChannelListController get _controller =>
      component.controller ?? _internalController!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Built here rather than in initState because it needs the client from an
    // inherited component, which is only safe to read once dependencies exist.
    if (component.controller == null && _internalController == null) {
      _internalController = StreamChannelListController(
        client: StreamChat.of(context).client,
        filter: component.filter,
        sort: component.sort,
        limit: component.limit,
      );
      unawaited(_internalController!.refresh());
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  void _onScroll(web.Event event) {
    // Interop types are erased, so `is` checks against them are meaningless.
    // The target of a scroll event is always the element the handler is bound
    // to, which makes the cast safe.
    final target = event.target as web.Element?;
    if (target == null) return;
    final remaining =
        target.scrollHeight - target.scrollTop - target.clientHeight;
    if (remaining <= _loadMoreThreshold) {
      unawaited(_controller.loadMore());
    }
  }

  @override
  Component build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context) {
        final controller = _controller;

        if (controller.isLoading && controller.channels.isEmpty) {
          return div([], classes: 'sc-spinner');
        }

        if (controller.error case final error? when controller.channels.isEmpty) {
          return div(
            [
              Component.text(
                StreamChat.translationsOf(context).loadChannelsFailed(error),
              ),
            ],
            classes: 'sc-error',
          );
        }

        if (controller.channels.isEmpty) {
          return component.empty ??
              div(
                [Component.text(StreamChat.translationsOf(context).noChannels)],
                classes: 'sc-empty',
              );
        }

        return div(
          [
            for (final channel in controller.channels)
              StreamChannelListTile(
                key: ValueKey(channel.cid),
                channel: channel,
                selected: channel.cid == component.selectedChannelCid,
                onTap: component.onChannelTap,
              ),
            if (controller.isLoadingMore) div([], classes: 'sc-spinner'),
          ],
          classes: 'sc-channel-list',
          events: {'scroll': _onScroll},
        );
      },
    );
  }
}
