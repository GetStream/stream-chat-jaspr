import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';
import 'package:test/test.dart';

void main() {
  group('detectAutocomplete', () {
    test('returns null for plain text', () {
      expect(detectAutocomplete('hello there', 11), isNull);
    });

    test('detects a mention at the caret', () {
      final query = detectAutocomplete('hi @al', 6);
      expect(query?.kind, AutocompleteKind.mention);
      expect(query?.query, 'al');
      expect(query?.start, 3);
      expect(query?.end, 6);
    });

    test('detects a mention with an empty query', () {
      expect(detectAutocomplete('@', 1)?.query, '');
    });

    test('ignores an at sign that follows a word character', () {
      expect(detectAutocomplete('mail me@ex', 10), isNull);
    });

    test('stops at whitespace before the caret', () {
      expect(detectAutocomplete('@al ready', 9), isNull);
    });

    test('detects a command at the start of the message', () {
      final query = detectAutocomplete('/gip', 4);
      expect(query?.kind, AutocompleteKind.command);
      expect(query?.query, 'gip');
    });

    test('stops offering a command once an argument is being typed', () {
      expect(detectAutocomplete('/giphy cats', 11), isNull);
    });

    test('does not treat a mid-message slash as a command', () {
      expect(detectAutocomplete('and/or', 6), isNull);
    });

    test('replaces the query and reports the new caret', () {
      final query = detectAutocomplete('hi @al', 6)!;
      final (text, caret) = query.apply('hi @al', 'alice');
      expect(text, 'hi @alice ');
      expect(caret, text.length);
    });

    test('keeps text after the caret when applying', () {
      final query = detectAutocomplete('hi @al there', 6)!;
      final (text, caret) = query.apply('hi @al there', 'alice');
      expect(text, 'hi @alice  there');
      expect(caret, 'hi @alice '.length);
    });
  });
}
