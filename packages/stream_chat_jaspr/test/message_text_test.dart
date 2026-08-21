import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';
import 'package:test/test.dart';

void main() {
  group('tokenizeMessageText', () {
    test('returns nothing for empty text', () {
      expect(tokenizeMessageText(''), isEmpty);
    });

    test('returns a single run for plain text', () {
      expect(
        tokenizeMessageText('just a sentence'),
        const [MessageToken(MessageTokenKind.text, 'just a sentence')],
      );
    });

    test('extracts a link', () {
      expect(
        tokenizeMessageText('see https://example.com now'),
        const [
          MessageToken(MessageTokenKind.text, 'see '),
          MessageToken(MessageTokenKind.link, 'https://example.com'),
          MessageToken(MessageTokenKind.text, ' now'),
        ],
      );
    });

    test('leaves trailing sentence punctuation out of a link', () {
      expect(
        tokenizeMessageText('read https://example.com/a.'),
        const [
          MessageToken(MessageTokenKind.text, 'read '),
          MessageToken(MessageTokenKind.link, 'https://example.com/a'),
          MessageToken(MessageTokenKind.text, '.'),
        ],
      );
    });

    test('keeps a link inside backticks literal', () {
      expect(
        tokenizeMessageText('`https://example.com`'),
        const [MessageToken(MessageTokenKind.code, 'https://example.com')],
      );
    });

    test('marks a mention that matches a known name', () {
      expect(
        tokenizeMessageText('hi @alice', mentionedNames: {'alice'}),
        const [
          MessageToken(MessageTokenKind.text, 'hi '),
          MessageToken(MessageTokenKind.mention, 'alice'),
        ],
      );
    });

    test('matches a mention regardless of case', () {
      expect(
        tokenizeMessageText('hi @Alice', mentionedNames: {'alice'}),
        const [
          MessageToken(MessageTokenKind.text, 'hi '),
          MessageToken(MessageTokenKind.mention, 'Alice'),
        ],
      );
    });

    test('leaves an unknown handle as plain text', () {
      expect(
        tokenizeMessageText('hi @nobody', mentionedNames: {'alice'}),
        const [MessageToken(MessageTokenKind.text, 'hi @nobody')],
      );
    });

    test('does not treat an email address as a mention', () {
      expect(
        tokenizeMessageText('mail me@alice.com', mentionedNames: {'alice'}),
        const [MessageToken(MessageTokenKind.text, 'mail me@alice.com')],
      );
    });

    test('merges text around a rejected mention into one run', () {
      final tokens = tokenizeMessageText('a @x b', mentionedNames: {});
      expect(tokens, hasLength(1));
      expect(tokens.single.value, 'a @x b');
    });
  });
}
