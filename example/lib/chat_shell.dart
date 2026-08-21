import 'package:jaspr/dom.dart' hide Filter;
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';

/// The two-pane chat layout: channel list on the left, conversation on the right.
///
/// Below 760px the two panes collapse into one and `data-pane` decides which
/// of them is visible, which is handled entirely in CSS. An open thread adds a
/// third column inside the conversation pane, which collapses the same way.
class ChatShell extends StatefulComponent {
  /// Creates the shell.
  const ChatShell({
    required this.isDark,
    required this.onToggleTheme,
    required this.onSignOut,
    super.key,
  });

  /// Whether the dark theme is active.
  final bool isDark;

  /// Toggles between the light and dark themes.
  final VoidCallback onToggleTheme;

  /// Disconnects the current user.
  final VoidCallback onSignOut;

  @override
  State<ChatShell> createState() => _ChatShellState();
}

class _ChatShellState extends State<ChatShell> {
  Channel? _selected;
  String? _highlightedMessageId;

  @override
  Component build(BuildContext context) {
    final selected = _selected;
    final currentUserId = StreamChat.of(context).currentUser?.id;

    return div(
      [
        div(
          [
            _sidebarHeader(context),
            const StreamConnectionStatusBanner(),
            if (currentUserId != null)
              StreamMessageSearchView(
                filter: Filter.in_('members', [currentUserId]),
                onResultTap: _onSearchResultTap,
              ),
            StreamChannelListView(
              selectedChannelCid: selected?.cid,
              onChannelTap: _select,
            ),
          ],
          classes: 'sc-channel-list-pane',
        ),
        div(
          [
            if (selected == null)
              div(
                [Component.text('Select a conversation to start chatting.')],
                classes: 'sc-empty',
              )
            else
              StreamChannel(
                // Keyed so switching channels rebuilds the scope and re-runs
                // the initial watch instead of reusing the previous state.
                key: ValueKey(selected.cid),
                channel: selected,
                child: Builder(builder: _conversation),
              ),
          ],
          classes: 'sc-channel-pane',
        ),
      ],
      classes: 'sc-shell',
      attributes: {'data-pane': selected == null ? 'list' : 'channel'},
    );
  }

  /// The conversation column plus the thread column, if one is open.
  ///
  /// Built through a [Builder] so that it runs below [StreamChannel] and can
  /// therefore read the open thread from the channel scope. That is where the
  /// action menu on a message puts it.
  Component _conversation(BuildContext context) {
    final channelState = StreamChannel.of(context);
    final thread = channelState.openThread;

    return div(
      [
        div(
          [
            StreamChannelHeader(leading: _backButton()),
            StreamMessageListView(highlightedMessageId: _highlightedMessageId),
            const StreamTypingIndicator(),
            const StreamMessageInput(),
          ],
          classes: 'sc-conversation',
        ),
        if (thread != null)
          StreamThreadView(
            key: ValueKey(thread.id),
            parent: thread,
            onClose: channelState.closeThread,
          ),
      ],
      classes: 'sc-conversation-split',
      attributes: {'data-thread': thread == null ? 'closed' : 'open'},
    );
  }

  void _select(Channel channel) {
    setState(() {
      _selected = channel;
      _highlightedMessageId = null;
    });
  }

  /// Opens the channel a search result belongs to and highlights the match.
  ///
  /// The message may be older than the loaded page, in which case it is not on
  /// screen yet. Paging back to it is the part the Flutter SDK solves with
  /// `idAround`, which this example does not attempt.
  void _onSearchResultTap(Message message, ChannelModel? channelModel) {
    final cid = channelModel?.cid;
    if (cid == null) return;

    final client = StreamChat.of(context).client;
    final channel = client.state.channels[cid];
    if (channel == null) return;

    setState(() {
      _selected = channel;
      _highlightedMessageId = message.id;
    });
  }

  Component _sidebarHeader(BuildContext context) {
    final user = StreamChat.of(context).currentUser;

    return div(
      [
        if (user != null) StreamAvatar.user(user, size: 32),
        div(
          [Component.text(user?.name ?? 'Signed in')],
          classes: 'app-sidebar-header__name',
        ),
        button(
          [Component.text(component.isDark ? '\u{2600}' : '\u{263D}')],
          type: ButtonType.button,
          classes: 'app-icon-button',
          attributes: {
            'aria-label': component.isDark
                ? 'Switch to light theme'
                : 'Switch to dark theme',
            'title': 'Toggle theme',
          },
          onClick: component.onToggleTheme,
        ),
        button(
          [Component.text('\u{23FB}')],
          type: ButtonType.button,
          classes: 'app-icon-button',
          attributes: {'aria-label': 'Sign out', 'title': 'Sign out'},
          onClick: component.onSignOut,
        ),
      ],
      classes: 'app-sidebar-header',
    );
  }

  Component _backButton() {
    return button(
      [Component.text('\u{2190}')],
      type: ButtonType.button,
      classes: 'app-icon-button app-back',
      attributes: {'aria-label': 'Back to channel list'},
      onClick: () => setState(() => _selected = null),
    );
  }
}
