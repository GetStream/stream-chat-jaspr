/// The kind of suggestion the composer should be offering.
enum AutocompleteKind {
  /// A user mention, triggered by `@`.
  mention,

  /// A slash command, triggered by `/` at the very start of the message.
  command,
}

/// An active autocomplete trigger in the composer.
class AutocompleteQuery {
  /// Creates a query.
  const AutocompleteQuery({
    required this.kind,
    required this.query,
    required this.start,
    required this.end,
  });

  /// What is being completed.
  final AutocompleteKind kind;

  /// The text typed after the trigger character.
  final String query;

  /// Index of the trigger character in the full text.
  final int start;

  /// Index just past the typed query, which is where the caret sits.
  final int end;

  /// Replaces this query in [text] with [value], returning the new text and
  /// where the caret should land.
  (String text, int caret) apply(String text, String value) {
    final prefix = text.substring(0, start);
    final suffix = text.substring(end);
    final trigger = kind == AutocompleteKind.mention ? '@' : '/';
    // A trailing space means the next word is typed normally instead of
    // extending the completion that was just accepted.
    final inserted = '$trigger$value ';
    return (prefix + inserted + suffix, prefix.length + inserted.length);
  }

  @override
  bool operator ==(Object other) =>
      other is AutocompleteQuery &&
      other.kind == kind &&
      other.query == query &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(kind, query, start, end);
}

/// Finds the autocomplete trigger the caret currently sits in, if any.
///
/// [caret] is the selection start in [text]. Returns `null` when the caret is
/// not inside a trigger, which is the usual case and means no popup.
///
/// A mention trigger runs from an `@` back-to-back with the caret, with no
/// whitespace in between and either the start of the message or whitespace in
/// front of it. That last condition is what stops an email address from
/// opening the popup halfway through typing it.
AutocompleteQuery? detectAutocomplete(String text, int caret) {
  if (caret < 0 || caret > text.length) return null;

  // Commands are only valid as the very first thing in a message, and only
  // until the first space, because everything after that is an argument.
  if (text.startsWith('/')) {
    final firstSpace = text.indexOf(' ');
    final withinCommand = firstSpace == -1 || caret <= firstSpace;
    if (withinCommand) {
      return AutocompleteQuery(
        kind: AutocompleteKind.command,
        query: text.substring(1, caret),
        start: 0,
        end: caret,
      );
    }
  }

  for (var i = caret - 1; i >= 0; i--) {
    final char = text[i];
    if (char == '@') {
      final before = i == 0 ? null : text[i - 1];
      if (before != null && !_isWhitespace(before)) return null;
      return AutocompleteQuery(
        kind: AutocompleteKind.mention,
        query: text.substring(i + 1, caret),
        start: i,
        end: caret,
      );
    }
    if (_isWhitespace(char)) return null;
    // A mention is a single word, so anything longer than a plausible
    // username means the `@` is too far back to still be one.
    if (caret - i > 64) return null;
  }

  return null;
}

bool _isWhitespace(String char) => char.trim().isEmpty;
