import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

/// Loads and maintains a paginated, live-updating list of channels.
///
/// This is a deliberately small stand-in for `StreamChannelListController` in
/// `stream_chat_flutter_core`, which is built on `PagedValueNotifier` and a
/// pluggable `StreamChannelListEventHandler`. Here the controller is a plain
/// [ChangeNotifier] holding a `List<Channel>`, with a fixed set of event
/// reactions that cover the common cases.
///
/// Pair it with a [ListenableBuilder], or let `StreamChannelListView` create
/// and own one for you.
class StreamChannelListController extends ChangeNotifier {
  /// Creates a controller. Call [refresh] to perform the first load.
  StreamChannelListController({
    required this.client,
    this.filter,
    SortOrder<ChannelState>? sort,
    this.limit = 20,
    this.messageLimit,
    this.memberLimit,
  }) : sort = sort ?? [const SortOption<ChannelState>.desc('last_message_at')];

  /// The client used to run the query.
  final StreamChatClient client;

  /// The query filter. Defaults to channels the current user is a member of.
  final Filter? filter;

  /// The sort order. Defaults to most recently active first.
  final SortOrder<ChannelState> sort;

  /// How many channels to fetch per page.
  final int limit;

  /// How many messages to prefetch per channel.
  final int? messageLimit;

  /// How many members to prefetch per channel.
  final int? memberLimit;

  final List<Channel> _channels = [];
  final List<StreamSubscription<Event>> _subscriptions = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  bool _disposed = false;
  Object? _error;

  /// The channels loaded so far.
  List<Channel> get channels => List.unmodifiable(_channels);

  /// Whether the first page is currently loading.
  bool get isLoading => _isLoading;

  /// Whether an additional page is currently loading.
  bool get isLoadingMore => _isLoadingMore;

  /// Whether another page may be available.
  bool get hasNextPage => _hasNextPage;

  /// The error from the last failed query, if any.
  Object? get error => _error;

  Filter get _effectiveFilter {
    if (filter case final filter?) return filter;
    final userId = client.state.currentUser?.id;
    if (userId == null) {
      throw StateError(
        'StreamChannelListController needs either an explicit filter or a '
        'connected user to derive the default "members" filter from.',
      );
    }
    return Filter.in_('members', [userId]);
  }

  /// Loads the first page, replacing anything already loaded.
  Future<void> refresh() async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final page = await _query(offset: 0);
      if (_disposed) return;
      _channels
        ..clear()
        ..addAll(page);
      _hasNextPage = page.length >= limit;
      _listenToEvents();
    } catch (e) {
      if (_disposed) return;
      _error = e;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Loads the next page and appends it.
  Future<void> loadMore() async {
    if (_disposed || _isLoading || _isLoadingMore || !_hasNextPage) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _query(offset: _channels.length);
      if (_disposed) return;
      final known = _channels.map((it) => it.cid).toSet();
      _channels.addAll(page.where((it) => !known.contains(it.cid)));
      _hasNextPage = page.length >= limit;
    } catch (e) {
      if (_disposed) return;
      _error = e;
    } finally {
      if (!_disposed) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<List<Channel>> _query({required int offset}) {
    // `queryChannels` emits the cached result first and the network result
    // after, then closes. `last` collapses that to the freshest page.
    return client
        .queryChannels(
          filter: _effectiveFilter,
          channelStateSort: sort,
          messageLimit: messageLimit,
          memberLimit: memberLimit,
          paginationParams: PaginationParams(limit: limit, offset: offset),
        )
        .last;
  }

  void _listenToEvents() {
    if (_subscriptions.isNotEmpty) return;

    void listen(Stream<Event> stream, void Function(Event event) handler) {
      _subscriptions.add(stream.listen(handler));
    }

    // A new message bumps its channel to the top, matching the default
    // `last_message_at` sort without re-running the query.
    listen(
      client.on(EventType.messageNew, EventType.notificationMessageNew),
      (event) {
        final cid = event.cid;
        if (cid == null) return;
        final index = _channels.indexWhere((it) => it.cid == cid);
        if (index > 0) {
          _channels.insert(0, _channels.removeAt(index));
          notifyListeners();
        } else if (index == -1) {
          // A channel we have not loaded became active — pull it in.
          unawaited(refresh());
        }
      },
    );

    listen(
      client.on(
        EventType.channelDeleted,
        EventType.channelHidden,
        EventType.notificationRemovedFromChannel,
      ),
      (event) {
        final cid = event.cid;
        if (cid == null) return;
        final removed = _channels.length;
        _channels.removeWhere((it) => it.cid == cid);
        if (_channels.length != removed) notifyListeners();
      },
    );

    listen(
      client.on(
        EventType.notificationAddedToChannel,
        EventType.channelVisible,
      ),
      (_) => unawaited(refresh()),
    );

    // Renames and image changes do not reorder the list but do change what the
    // tiles render.
    listen(client.on(EventType.channelUpdated), (_) => notifyListeners());
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    super.dispose();
  }
}
