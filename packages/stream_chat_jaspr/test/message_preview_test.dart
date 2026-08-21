import 'package:stream_chat/stream_chat.dart';
import 'package:stream_chat_jaspr/src/util/channel_display.dart';
import 'package:test/test.dart';

void main() {
  final alice = User(id: 'alice', name: 'Alice');
  final bob = User(id: 'bob', name: 'Bob');

  group('messagePreview', () {
    test('handles a missing message', () {
      expect(messagePreview(null), 'No messages yet');
    });

    test('prefixes the current user with "You"', () {
      final message = Message(text: 'hello', user: alice);
      expect(
        messagePreview(message, currentUserId: 'alice'),
        'You: hello',
      );
    });

    test('prefixes other users with their name', () {
      final message = Message(text: 'hello', user: bob);
      expect(messagePreview(message, currentUserId: 'alice'), 'Bob: hello');
    });

    test('collapses newlines into a single line', () {
      final message = Message(text: 'line one\n\nline two', user: bob);
      expect(
        messagePreview(message, currentUserId: 'alice'),
        'Bob: line one line two',
      );
    });

    test('describes an image attachment when there is no text', () {
      final message = Message(
        user: bob,
        attachments: [Attachment(type: AttachmentType.image)],
      );
      expect(messagePreview(message, currentUserId: 'alice'), 'Bob: Photo');
    });

    test('counts extra attachments', () {
      final message = Message(
        user: bob,
        attachments: [
          Attachment(type: AttachmentType.video),
          Attachment(type: AttachmentType.video),
          Attachment(type: AttachmentType.video),
        ],
      );
      expect(messagePreview(message, currentUserId: 'alice'), 'Bob: Video +2');
    });

    test('reports deleted messages without an author prefix', () {
      final message = Message(
        text: 'secret',
        user: bob,
        type: MessageType.deleted,
      );
      expect(
        messagePreview(message, currentUserId: 'alice'),
        'This message was deleted',
      );
    });
  });
}
