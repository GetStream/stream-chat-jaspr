import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../i18n/stream_chat_translations.dart';
import '../theme/stream_chat_styles.dart';
import '../theme/stream_chat_theme.dart';

/// Provides a [StreamChatClient] and a [StreamChatTheme] to the component tree.
///
/// Mount this above anything that uses the components in this package:
///
/// ```dart
/// StreamChat(
///   client: client,
///   child: MyChatPage(),
/// )
/// ```
///
/// This is the Jaspr counterpart of `StreamChatCore` in the Flutter SDK, minus
/// the app-lifecycle machinery. Mobile platforms suspend apps and tear down
/// sockets, so the Flutter version disconnects after a keep-alive window and
/// reconnects on resume. Browsers keep websockets open in background tabs and
/// the low level client already reconnects with backoff on transport errors,
/// so there is nothing equivalent to do here.
class StreamChat extends StatefulComponent {
  /// Creates a Stream Chat scope around [child].
  const StreamChat({
    required this.client,
    required this.child,
    this.theme,
    this.translations = const StreamChatTranslations(),
    this.injectStyles = true,
    super.key,
  });

  /// The client every descendant component reads from.
  ///
  /// Connecting the user is left to the application, exactly as in the Flutter
  /// SDK. Call `client.connectUser(...)` before or after mounting.
  final StreamChatClient client;

  /// The subtree that gets access to [client].
  final Component child;

  /// Design tokens for the components below. Defaults to [StreamChatTheme.light].
  final StreamChatTheme? theme;

  /// Strings for the components below. Defaults to English.
  final StreamChatTranslations translations;

  /// Whether to render [streamChatStyles] into a `<style>` element.
  ///
  /// Set to `false` if you ship the stylesheet yourself, for example to render
  /// it once at the document level instead of per chat surface.
  final bool injectStyles;

  /// The closest [StreamChatState] above [context].
  ///
  /// Throws if there is no [StreamChat] ancestor.
  static StreamChatState of(BuildContext context) {
    final state = maybeOf(context);
    if (state == null) {
      throw StateError(
        'No StreamChat ancestor found.\n'
        'Wrap your chat components in a StreamChat component to give them '
        'access to a StreamChatClient.',
      );
    }
    return state;
  }

  /// The closest [StreamChatState] above [context], or `null`.
  static StreamChatState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<StreamChatScope>()
        ?.state;
  }

  /// The theme provided by the closest [StreamChat] ancestor.
  static StreamChatTheme themeOf(BuildContext context) => of(context).theme;

  /// The translations provided by the closest [StreamChat] ancestor.
  ///
  /// Falls back to English when there is no ancestor, so leaf components can
  /// be rendered in isolation, which is mostly useful in tests.
  static StreamChatTranslations translationsOf(BuildContext context) {
    return maybeOf(context)?.translations ?? const StreamChatTranslations();
  }

  @override
  State<StreamChat> createState() => StreamChatState();
}

/// State of a [StreamChat] scope. Obtain it with `StreamChat.of(context)`.
class StreamChatState extends State<StreamChat> {
  /// The client provided to this subtree.
  StreamChatClient get client => component.client;

  /// The active theme.
  StreamChatTheme get theme => component.theme ?? _fallbackTheme;

  /// The active translations.
  StreamChatTranslations get translations => component.translations;

  late final StreamChatTheme _fallbackTheme = StreamChatTheme.light();

  /// The currently connected user, if any.
  OwnUser? get currentUser => client.state.currentUser;

  /// Emits whenever the connected user changes.
  Stream<OwnUser?> get currentUserStream => client.state.currentUserStream;

  /// Emits the websocket connection status.
  Stream<ConnectionStatus> get connectionStatusStream =>
      client.wsConnectionStatusStream;

  @override
  Component build(BuildContext context) {
    return StreamChatScope(
      state: this,
      theme: theme,
      translations: translations,
      child: div(
        [
          if (component.injectStyles) Style(styles: streamChatStyles),
          component.child,
        ],
        classes: 'sc-root',
        // The theme is applied as CSS custom properties on this one element.
        // Everything below resolves its colours through them, so changing the
        // theme never rebuilds the subtree.
        styles: Styles(raw: theme.cssVariables),
      ),
    );
  }
}

/// The [InheritedComponent] that carries the [StreamChatState] down the tree.
///
/// Exposed so custom components can depend on it directly; most code should
/// use [StreamChat.of] instead.
class StreamChatScope extends InheritedComponent {
  /// Creates the scope.
  const StreamChatScope({
    required this.state,
    required this.theme,
    required this.translations,
    required super.child,
    super.key,
  });

  /// The state being provided.
  final StreamChatState state;

  /// The theme being provided.
  final StreamChatTheme theme;

  /// The translations being provided.
  final StreamChatTranslations translations;

  @override
  bool updateShouldNotify(StreamChatScope oldComponent) =>
      state != oldComponent.state ||
      theme != oldComponent.theme ||
      translations != oldComponent.translations;
}
