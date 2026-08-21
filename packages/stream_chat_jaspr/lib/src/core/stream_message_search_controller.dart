import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

/// Runs message searches and holds their results.
///
/// Searching is a paginated query against the API rather than a filter over
/// loaded state, so it needs the same shape of controller as the channel list:
/// a term, a page of results, and a cursor for the next page.
///
/// Queries are debounced because the field searches as you type. Results are
/// keyed to the term that produced them, so a slow response for an earlier
/// term cannot overwrite the results of a later one.
class StreamMessageSearchController extends ChangeNotifier {
  /// Creates a search controller.
  ///
  /// [filter] scopes the search, usually to the channels the current user is a
  /// member of. Stream requires one, since searching every channel in an
  /// application is not something the API allows.
  StreamMessageSearchController({
    required this.client,
    required this.filter,
    this.pageSize = 20,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// The client the search runs on.
  final StreamChatClient client;

  /// The channel filter the search is scoped to.
  final Filter filter;

  /// How many results to fetch per page.
  final int pageSize;

  /// How long to wait after the last keystroke before querying.
  final Duration debounce;

  String _term = '';
  List<GetMessageResponse> _results = const [];
  String? _next;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  Object? _error;
  Timer? _debounceTimer;

  /// The term currently being searched.
  String get term => _term;

  /// Results for [term], newest match first.
  List<GetMessageResponse> get results => _results;

  /// Whether the first page is in flight.
  bool get isLoading => _isLoading;

  /// Whether a further page is in flight.
  bool get isLoadingMore => _isLoadingMore;

  /// The last failure, if the most recent query failed.
  Object? get error => _error;

  /// Whether the API reported more results after the current page.
  bool get hasMore => _next != null;

  /// Whether a search is active at all.
  bool get isActive => _term.trim().isNotEmpty;

  /// Sets the term and schedules a search.
  ///
  /// Clearing the term cancels any pending query and empties the results
  /// immediately, so the UI never shows stale matches under an empty field.
  void search(String term) {
    if (_term == term) return;
    _term = term;
    _debounceTimer?.cancel();

    if (!isActive) {
      _results = const [];
      _next = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    _debounceTimer = Timer(debounce, () => unawaited(_run(term)));
  }

  /// Clears the term and the results.
  void clear() => search('');

  Future<void> _run(String term) async {
    try {
      final response = await client.search(
        filter,
        query: term,
        paginationParams: PaginationParams(limit: pageSize),
      );
      // A response for a term the user has already moved on from is not worth
      // rendering, and would otherwise arrive after the newer one.
      if (term != _term) return;
      _results = response.results;
      _next = response.next;
      _error = null;
    } catch (error) {
      if (term != _term) return;
      _error = error;
      _results = const [];
      _next = null;
    } finally {
      if (term == _term) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Appends the next page of results, if there is one.
  Future<void> loadMore() async {
    final next = _next;
    if (next == null || _isLoadingMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    final term = _term;
    try {
      final response = await client.search(
        filter,
        query: term,
        paginationParams: PaginationParams(limit: pageSize, next: next),
      );
      if (term != _term) return;
      _results = [..._results, ...response.results];
      _next = response.next;
    } catch (error) {
      if (term == _term) _error = error;
    } finally {
      if (term == _term) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
