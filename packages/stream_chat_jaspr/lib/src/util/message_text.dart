/// What a run of message text represents.
enum MessageTokenKind {
  /// Ordinary text.
  text,

  /// An absolute http or https URL.
  link,

  /// A mention of a user in the conversation.
  mention,

  /// A run of inline code delimited by backticks.
  code,
}

/// A run of message text of a single kind.
class MessageToken {
  /// Creates a token.
  const MessageToken(this.kind, this.value);

  /// What the run represents.
  final MessageTokenKind kind;

  /// The text of the run, with any delimiters removed.
  final String value;

  @override
  String toString() => 'MessageToken(${kind.name}, $value)';

  @override
  bool operator ==(Object other) =>
      other is MessageToken && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

/// Matches links, inline code, and mention-shaped words in one pass.
///
/// Ordering matters: code is matched before links so that a URL inside
/// backticks stays literal, and links are matched before mentions so that an
/// email-like fragment in a query string is not mistaken for one.
final RegExp _tokenPattern = RegExp(
  r'`([^`\n]+)`'
  r'|(https?://[^\s<>"]+[^\s<>"“”‘’.,:;!?)\]}])'
  r'|(?<![\w@])@([\w.\-]{1,64})',
);

/// Splits [text] into runs that a renderer can style individually.
///
/// This is deliberately not a Markdown parser. The Flutter SDK renders
/// messages with `flutter_markdown`, but the overwhelming majority of what
/// that buys is links, and a full parser would either pull in a dependency or
/// grow into one. Bold and italic are left as literal characters rather than
/// half-supported.
///
/// A mention is only recognised when the word after `@` matches one of
/// [mentionedNames], compared case insensitively. Without that check any email
/// address or handle typed in passing would be highlighted as though it
/// notified someone.
List<MessageToken> tokenizeMessageText(
  String text, {
  Set<String> mentionedNames = const {},
}) {
  if (text.isEmpty) return const [];

  final lowercased = {for (final name in mentionedNames) name.toLowerCase()};
  final tokens = <MessageToken>[];
  var cursor = 0;

  void addText(String value) {
    if (value.isEmpty) return;
    // Merge with the previous run so that a rejected mention does not split
    // one sentence into three text tokens.
    if (tokens.isNotEmpty && tokens.last.kind == MessageTokenKind.text) {
      final merged = tokens.removeLast().value + value;
      tokens.add(MessageToken(MessageTokenKind.text, merged));
      return;
    }
    tokens.add(MessageToken(MessageTokenKind.text, value));
  }

  for (final match in _tokenPattern.allMatches(text)) {
    addText(text.substring(cursor, match.start));
    cursor = match.end;

    if (match.group(1) case final code?) {
      tokens.add(MessageToken(MessageTokenKind.code, code));
    } else if (match.group(2) case final link?) {
      tokens.add(MessageToken(MessageTokenKind.link, link));
    } else if (match.group(3) case final handle?) {
      if (lowercased.contains(handle.toLowerCase())) {
        tokens.add(MessageToken(MessageTokenKind.mention, handle));
      } else {
        addText(match.group(0)!);
      }
    }
  }

  addText(text.substring(cursor));
  return tokens;
}
