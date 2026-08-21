import 'package:jaspr/dom.dart';

/// The overall brightness of a [StreamChatTheme].
enum StreamChatBrightness {
  /// Dark text on light surfaces.
  light,

  /// Light text on dark surfaces.
  dark,
}

/// Design tokens for the Stream Chat Jaspr components.
///
/// Unlike the Flutter SDK — where the theme is read from the component tree on
/// every build — this theme is emitted once as a set of CSS custom properties
/// on the root element. Every component stylesheet is written against those
/// variables, so swapping a theme is a single attribute update on one element
/// rather than a rebuild of the whole subtree.
///
/// ```dart
/// StreamChat(
///   client: client,
///   theme: StreamChatTheme.dark(),
///   child: MyChatPage(),
/// )
/// ```
class StreamChatTheme {
  /// Creates a theme from raw token values.
  ///
  /// Prefer [StreamChatTheme.light] or [StreamChatTheme.dark] and override only
  /// the tokens you care about via [copyWith].
  const StreamChatTheme({
    required this.brightness,
    required this.primary,
    required this.primaryHover,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceHover,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.bubbleOwn,
    required this.bubbleOwnText,
    required this.bubbleOther,
    required this.bubbleOtherText,
    required this.online,
    required this.danger,
    this.fontFamily =
        "system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    this.borderRadius = '18px',
  });

  /// The default light theme.
  factory StreamChatTheme.light() => const StreamChatTheme(
        brightness: StreamChatBrightness.light,
        primary: Color('#005fff'),
        primaryHover: Color('#0047cc'),
        onPrimary: Color('#ffffff'),
        background: Color('#ffffff'),
        surface: Color('#f7f7f8'),
        surfaceHover: Color('#ececed'),
        border: Color('#e3e5e8'),
        textPrimary: Color('#0d0e10'),
        textSecondary: Color('#72767e'),
        bubbleOwn: Color('#005fff'),
        bubbleOwnText: Color('#ffffff'),
        bubbleOther: Color('#f0f1f3'),
        bubbleOtherText: Color('#0d0e10'),
        online: Color('#20e070'),
        danger: Color('#ff3742'),
      );

  /// The default dark theme.
  factory StreamChatTheme.dark() => const StreamChatTheme(
        brightness: StreamChatBrightness.dark,
        primary: Color('#337eff'),
        primaryHover: Color('#5c98ff'),
        onPrimary: Color('#ffffff'),
        background: Color('#101418'),
        surface: Color('#181c22'),
        surfaceHover: Color('#232830'),
        border: Color('#2b313a'),
        textPrimary: Color('#f2f4f7'),
        textSecondary: Color('#8f959f'),
        bubbleOwn: Color('#337eff'),
        bubbleOwnText: Color('#ffffff'),
        bubbleOther: Color('#232830'),
        bubbleOtherText: Color('#f2f4f7'),
        online: Color('#20e070'),
        danger: Color('#ff5c68'),
      );

  /// Whether this theme is light or dark.
  final StreamChatBrightness brightness;

  /// Accent colour used for primary actions and own message bubbles.
  final Color primary;

  /// Hover state of [primary].
  final Color primaryHover;

  /// Foreground colour used on top of [primary].
  final Color onPrimary;

  /// The page background.
  final Color background;

  /// Background of raised panels such as the channel list.
  final Color surface;

  /// Hover state of [surface].
  final Color surfaceHover;

  /// Colour of separators and outlines.
  final Color border;

  /// Primary body text colour.
  final Color textPrimary;

  /// Muted text colour used for timestamps and previews.
  final Color textSecondary;

  /// Background of the current user's message bubbles.
  final Color bubbleOwn;

  /// Text colour inside [bubbleOwn].
  final Color bubbleOwnText;

  /// Background of other users' message bubbles.
  final Color bubbleOther;

  /// Text colour inside [bubbleOther].
  final Color bubbleOtherText;

  /// Colour of the online presence indicator.
  final Color online;

  /// Colour used for errors and destructive actions.
  final Color danger;

  /// Font stack applied to the whole chat surface.
  final String fontFamily;

  /// Corner radius of message bubbles.
  final String borderRadius;

  /// The CSS custom properties that back [streamChatStyles].
  ///
  /// Applied to the root element by [StreamChat]; every rule in the stylesheet
  /// resolves its colours through these.
  Map<String, String> get cssVariables => {
        '--sc-primary': primary.value,
        '--sc-primary-hover': primaryHover.value,
        '--sc-on-primary': onPrimary.value,
        '--sc-background': background.value,
        '--sc-surface': surface.value,
        '--sc-surface-hover': surfaceHover.value,
        '--sc-border': border.value,
        '--sc-text-primary': textPrimary.value,
        '--sc-text-secondary': textSecondary.value,
        '--sc-bubble-own': bubbleOwn.value,
        '--sc-bubble-own-text': bubbleOwnText.value,
        '--sc-bubble-other': bubbleOther.value,
        '--sc-bubble-other-text': bubbleOtherText.value,
        '--sc-online': online.value,
        '--sc-danger': danger.value,
        '--sc-font-family': fontFamily,
        '--sc-radius': borderRadius,
      };

  /// Returns a copy of this theme with the given tokens replaced.
  StreamChatTheme copyWith({
    StreamChatBrightness? brightness,
    Color? primary,
    Color? primaryHover,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? surfaceHover,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? bubbleOwn,
    Color? bubbleOwnText,
    Color? bubbleOther,
    Color? bubbleOtherText,
    Color? online,
    Color? danger,
    String? fontFamily,
    String? borderRadius,
  }) {
    return StreamChatTheme(
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      onPrimary: onPrimary ?? this.onPrimary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      bubbleOwn: bubbleOwn ?? this.bubbleOwn,
      bubbleOwnText: bubbleOwnText ?? this.bubbleOwnText,
      bubbleOther: bubbleOther ?? this.bubbleOther,
      bubbleOtherText: bubbleOtherText ?? this.bubbleOtherText,
      online: online ?? this.online,
      danger: danger ?? this.danger,
      fontFamily: fontFamily ?? this.fontFamily,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }
}
