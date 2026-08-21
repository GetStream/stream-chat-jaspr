import 'package:jaspr/dom.dart' hide Filter;
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';

/// The two-pane chat layout: channel list on the left, conversation on the right.
///
/// Below 760px the two panes collapse into one and `data-pane` decides which
/// of them is visible, which is handled entirely in CSS.
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

  @override
  Component build(BuildContext context) {
    final selected = _selected;

    return div(
      [
        div(
          [
            _sidebarHeader(context),
            const StreamConnectionStatusBanner(),
            StreamChannelListView(
              selectedChannelCid: selected?.cid,
              onChannelTap: (channel) => setState(() => _selected = channel),
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
                child: Component.fragment([
                  StreamChannelHeader(leading: _backButton()),
                  const StreamMessageListView(),
                  const StreamTypingIndicator(),
                  const StreamMessageInput(),
                ]),
              ),
          ],
          classes: 'sc-channel-pane',
        ),
      ],
      classes: 'sc-shell',
      attributes: {'data-pane': selected == null ? 'list' : 'channel'},
    );
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
            'aria-label':
                component.isDark ? 'Switch to light theme' : 'Switch to dark theme',
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
