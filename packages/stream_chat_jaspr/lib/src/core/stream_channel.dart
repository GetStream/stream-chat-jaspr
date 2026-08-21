import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import 'stream_message_composer_controller.dart';

/// Provides a watched [Channel] to the component tree.
///
/// A [Channel] straight out of `client.channel(...)` has no state until it has
/// been watched. This component performs that initial `watch()` and only
/// renders [child] once the channel state is available, so descendants can
/// read `channel.state` without null checks.
///
/// ```dart
/// StreamChannel(
///   channel: client.channel('messaging', id: 'general'),
///   child: StreamMessageListView(),
/// )
/// ```
class StreamChannel extends StatefulComponent {
  /// Creates a channel scope around [child].
  const StreamChannel({
    required this.channel,
    required this.child,
    this.loading,
    this.errorBuilder,
    super.key,
  });

  /// The channel to watch and provide.
  final Channel channel;

  /// Rendered once the channel is initialised.
  final Component child;

  /// Rendered while the initial `watch()` is in flight.
  final Component? loading;

  /// Rendered if the initial `watch()` fails.
  final Component Function(BuildContext context, Object error)? errorBuilder;

  /// The closest [StreamChannelState] above [context].
  ///
  /// Throws if there is no [StreamChannel] ancestor.
  static StreamChannelState of(BuildContext context) {
    final state = maybeOf(context);
    if (state == null) {
      throw StateError(
        'No StreamChannel ancestor found.\n'
        'Wrap this component in a StreamChannel to give it access to a Channel.',
      );
    }
    return state;
  }

  /// The closest [StreamChannelState] above [context], or `null`.
  static StreamChannelState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<StreamChannelScope>()
        ?.state;
  }

  @override
  State<StreamChannel> createState() => StreamChannelState();
}

/// State of a [StreamChannel] scope. Obtain it with `StreamChannel.of(context)`.
class StreamChannelState extends State<StreamChannel> {
  /// The channel provided to this subtree.
  Channel get channel => component.channel;

  /// The composer state for the main conversation.
  ///
  /// A thread pane installs its own controller, so this one always refers to
  /// the draft for the channel itself.
  StreamMessageComposerController get composer => _composer;

  /// Resolves once the channel has been watched.
  late Future<void> _initialized;
  late StreamMessageComposerController _composer;

  /// The message whose thread is open, if any.
  Message? _openThread;

  /// The thread currently open in this channel, if any.
  Message? get openThread => _openThread;

  /// Opens the thread rooted at [message].
  void openThreadFor(Message message) {
    if (_openThread?.id == message.id) return;
    setState(() => _openThread = message);
  }

  /// Closes the open thread.
  void closeThread() {
    if (_openThread == null) return;
    setState(() => _openThread = null);
  }

  @override
  void initState() {
    super.initState();
    _initialized = _watch();
    _composer = StreamMessageComposerController();
  }

  @override
  void didUpdateComponent(StreamChannel oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.channel.cid != component.channel.cid) {
      _composer.dispose();
      setState(() {
        _initialized = _watch();
        _composer = StreamMessageComposerController();
        _openThread = null;
      });
    }
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _watch() async {
    // `watch()` is idempotent on an already-initialised channel but still costs
    // a round trip, so skip it when state is already there (for example for
    // channels that arrived fully hydrated from `queryChannels`).
    if (channel.state != null) return;
    await channel.watch();
  }

  /// Marks the channel as read for the current user.
  Future<void> markRead() => channel.markRead();

  @override
  Component build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialized,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error!;
          final builder = component.errorBuilder;
          if (builder != null) return builder(context, error);
          return div([Component.text('$error')], classes: 'sc-error');
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return component.loading ?? div([], classes: 'sc-spinner');
        }
        return StreamChannelScope(
          state: this,
          openThreadId: _openThread?.id,
          child: StreamComposerScope(
            controller: _composer,
            child: component.child,
          ),
        );
      },
    );
  }
}

/// The [InheritedComponent] that carries the [StreamChannelState] down the tree.
class StreamChannelScope extends InheritedComponent {
  /// Creates the scope.
  const StreamChannelScope({
    required this.state,
    required this.openThreadId,
    required super.child,
    super.key,
  });

  /// The state being provided.
  final StreamChannelState state;

  /// Id of the message whose thread is open.
  ///
  /// Carried on the scope rather than read off [state] so that opening or
  /// closing a thread notifies dependents. Reading it from the mutable state
  /// object would not, because the object identity never changes.
  final String? openThreadId;

  @override
  bool updateShouldNotify(StreamChannelScope oldComponent) =>
      state.channel.cid != oldComponent.state.channel.cid ||
      openThreadId != oldComponent.openThreadId;
}
