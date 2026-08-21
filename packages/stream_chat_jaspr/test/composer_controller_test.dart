import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';
import 'package:test/test.dart';

void main() {
  group('StreamMessageComposerController', () {
    late StreamMessageComposerController controller;

    setUp(() => controller = StreamMessageComposerController());
    tearDown(() => controller.dispose());

    test('starts empty', () {
      expect(controller.text, isEmpty);
      expect(controller.isNotEmpty, isFalse);
      expect(controller.buildMessage(), isNull);
    });

    test('whitespace alone is not worth sending', () {
      controller.text = '   ';
      expect(controller.isNotEmpty, isFalse);
      expect(controller.buildMessage(), isNull);
    });

    test('notifies when the text changes', () {
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.text = 'hi';
      expect(notifications, 1);

      // Setting the same value again is not a change.
      controller.text = 'hi';
      expect(notifications, 1);
    });

    test('trims the text of the built message', () {
      controller.text = '  hello  ';
      expect(controller.buildMessage()?.text, 'hello');
    });

    test('carries the quoted message id', () {
      final quoted = Message(id: 'm1', text: 'original');
      controller
        ..text = 'replying'
        ..quote(quoted);

      expect(controller.quotedMessage, quoted);
      expect(controller.buildMessage()?.quotedMessageId, 'm1');
    });

    test('clearing the quote drops it from the built message', () {
      controller
        ..text = 'hi'
        ..quote(Message(id: 'm1'))
        ..clearQuote();

      expect(controller.quotedMessage, isNull);
      expect(controller.buildMessage()?.quotedMessageId, isNull);
    });

    test('editing loads the message and returns it with the new text', () {
      final original = Message(id: 'm2', text: 'befor');
      controller.edit(original);
      expect(controller.text, 'befor');
      expect(controller.isEditing, isTrue);

      controller.text = 'before';
      final built = controller.buildMessage();
      expect(built?.id, 'm2');
      expect(built?.text, 'before');
    });

    test('quoting while editing cancels the edit', () {
      controller
        ..edit(Message(id: 'm3', text: 'draft'))
        ..quote(Message(id: 'm4'));

      expect(controller.isEditing, isFalse);
      expect(controller.editedMessage, isNull);
    });

    test('cancelling an edit clears the draft', () {
      controller
        ..edit(Message(id: 'm5', text: 'draft'))
        ..cancelEdit();

      expect(controller.isEditing, isFalse);
      expect(controller.text, isEmpty);
    });

    test('reset clears everything', () {
      controller
        ..text = 'hi'
        ..quote(Message(id: 'm6'))
        ..reset();

      expect(controller.text, isEmpty);
      expect(controller.quotedMessage, isNull);
      expect(controller.attachments, isEmpty);
    });

    group('in a thread', () {
      late StreamMessageComposerController thread;

      setUp(
        () => thread = StreamMessageComposerController(parentId: 'parent-1'),
      );
      tearDown(() => thread.dispose());

      test('stamps the parent id onto the built message', () {
        thread.text = 'a reply';
        expect(thread.isThread, isTrue);
        expect(thread.buildMessage()?.parentId, 'parent-1');
      });

      test('omits showInChannel unless it was asked for', () {
        thread.text = 'a reply';
        expect(thread.buildMessage()?.showInChannel, isNull);

        thread.showInChannel = true;
        expect(thread.buildMessage()?.showInChannel, isTrue);
      });
    });
  });
}
