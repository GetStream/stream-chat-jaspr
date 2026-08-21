import 'dart:async';

import 'package:jaspr/dom.dart' hide Filter;
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';

import 'app_styles.dart';
import 'chat_shell.dart';
import 'demo_credentials.dart';
import 'sign_in_page.dart';

/// Root of the example app.
///
/// Owns the client lifecycle: unauthenticated it shows a sign-in screen, and
/// once `connectUser` succeeds it hands the client to [StreamChat] and renders
/// the chat shell.
class App extends StatefulComponent {
  /// Creates the app.
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamChatClient? _client;
  bool _isConnecting = false;
  Object? _error;
  bool _isDark = false;

  Future<void> _connect(DemoCredentials credentials) async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    final client = StreamChatClient(
      credentials.apiKey,
      logLevel: Level.WARNING,
    );

    try {
      await client.connectUser(
        User(id: credentials.userId),
        credentials.token,
      );
      if (!mounted) return;
      setState(() {
        _client = client;
        _isConnecting = false;
      });
    } catch (error) {
      unawaited(client.dispose());
      if (!mounted) return;
      setState(() {
        _error = error;
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnect() async {
    final client = _client;
    setState(() => _client = null);
    if (client == null) return;
    await client.disconnectUser();
    await client.dispose();
  }

  @override
  Component build(BuildContext context) {
    final client = _client;
    final theme = _isDark ? StreamChatTheme.dark() : StreamChatTheme.light();

    // Rendered even on the sign-in screen so that page can use the same
    // colour tokens as the chat itself.
    final chrome = Style(styles: appStyles);

    if (client == null) {
      return StreamChatThemeSurface(
        theme: theme,
        children: [
          chrome,
          SignInPage(
            isConnecting: _isConnecting,
            error: _error,
            onSignIn: (credentials) => unawaited(_connect(credentials)),
          ),
        ],
      );
    }

    return StreamChat(
      client: client,
      theme: theme,
      child: Component.fragment([
        chrome,
        ChatShell(
          isDark: _isDark,
          onToggleTheme: () => setState(() => _isDark = !_isDark),
          onSignOut: () => unawaited(_disconnect()),
        ),
      ]),
    );
  }
}

/// Applies the Stream theme tokens and stylesheet without a client.
///
/// [StreamChat] normally does this, but the sign-in screen runs before a
/// client exists and still wants the same look.
class StreamChatThemeSurface extends StatelessComponent {
  /// Creates a themed surface.
  const StreamChatThemeSurface({
    required this.theme,
    required this.children,
    super.key,
  });

  /// Tokens to apply.
  final StreamChatTheme theme;

  /// Content rendered inside the themed root.
  final List<Component> children;

  @override
  Component build(BuildContext context) {
    return div(
      [Style(styles: streamChatStyles), ...children],
      classes: 'sc-root',
      styles: Styles(raw: theme.cssVariables),
    );
  }
}
