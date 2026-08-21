import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../core/stream_channel.dart';
import '../core/stream_chat.dart';
import '../core/stream_message_composer_controller.dart';
import '../util/icons.dart';
import 'stream_message_input.dart';
import 'stream_message_list_view.dart';
import 'stream_message_tile.dart';

/// The replies to a single message, with their own composer.
///
/// Installs a second [StreamMessageComposerController] scoped to the thread,
/// so the draft here and the draft in the main conversation do not overwrite
/// each other. Everything below this component resolves the thread controller
/// instead of the channel one, because the nearest scope wins.
class StreamThreadView extends StatefulComponent {
  /// Creates a thread pane for [parent].
  const StreamThreadView({
    required this.parent,
    required this.onClose,
    this.pageSize = 25,
    super.key,
  });

  /// The message the replies hang off.
  final Message parent;

  /// Called when the pane should close.
  final void Function() onClose;

  /// How many replies to fetch per page.
  final int pageSize;

  @override
  State<StreamThreadView> createState() => _StreamThreadViewState();
}

class _StreamThreadViewState extends State<StreamThreadView> {
  late StreamMessageComposerController _composer;
  late Future<void> _loaded;

  @override
  void initState() {
    super.initState();
    _composer = StreamMessageComposerController(parentId: component.parent.id);
    _loaded = _loadReplies();
  }

  @override
  void didUpdateComponent(StreamThreadView oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.parent.id != component.parent.id) {
      _composer.dispose();
      setState(() {
        _composer =
            StreamMessageComposerController(parentId: component.parent.id);
        _loaded = _loadReplies();
      });
    }
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  /// Fetches the first page of replies into channel state.
  ///
  /// The list itself renders from `channel.state.threads`, which the client
  /// keeps up to date from websocket events. This only primes it, because a
  /// thread opened for the first time has nothing in state yet.
  Future<void> _loadReplies() async {
    final channel = StreamChannel.of(context).channel;
    if (channel.state?.threads[component.parent.id]?.isNotEmpty ?? false) {
      return;
    }
    await channel.getReplies(
      component.parent.id,
      options: PaginationParams(limit: component.pageSize),
    );
  }

  @override
  Component build(BuildContext context) {
    final translations = StreamChat.translationsOf(context);
    final currentUserId = StreamChat.of(context).currentUser?.id;

    return StreamComposerScope(
      controller: _composer,
      child: div(
        [
          div(
            [
              span(
                [Component.text(translations.thread)],
                classes: 'sc-channel-header__title',
              ),
              button(
                [StreamIcons.close()],
                type: ButtonType.button,
                classes: 'sc-icon-button',
                attributes: {'aria-label': translations.closeThread},
                onClick: component.onClose,
              ),
            ],
            classes: 'sc-thread__header',
          ),
          div(
            [
              StreamMessageTile(
                message: component.parent,
                isOwn: component.parent.user?.id == currentUserId,
                showThreadFooter: false,
              ),
            ],
            classes: 'sc-thread__parent',
          ),
          FutureBuilder<void>(
            future: _loaded,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return div([], classes: 'sc-spinner');
              }
              return StreamMessageListView(
                parentId: component.parent.id,
                pageSize: component.pageSize,
                markReadOnView: false,
              );
            },
          ),
          const StreamMessageInput(),
        ],
        classes: 'sc-thread',
        attributes: const {'role': 'complementary'},
      ),
    );
  }
}
