// The README promises these snippets compile. Nothing here is executed; the
// value is in the analyzer and the compiler seeing them.
import 'package:jaspr/dom.dart' hide Filter; // stream_chat also exports a Filter
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';
import 'package:test/test.dart';

class GermanTranslations extends StreamChatTranslations {
  const GermanTranslations();

  @override
  String get sendAMessage => 'Nachricht senden';

  @override
  String get replyInThread => 'Im Thread antworten';
}

Component quickStart(StreamChatClient client) {
  return StreamChat(
    client: client,
    theme: StreamChatTheme.dark(),
    translations: const GermanTranslations(),
    child: StreamChannel(
      channel: client.channel('messaging', id: 'general'),
      child: Component.fragment([
        StreamChannelHeader(),
        StreamMessageListView(),
        const StreamTypingIndicator(),
        const StreamMessageInput(),
      ]),
    ),
  );
}

Component conversationWithThread(Channel channel) {
  return StreamChannel(
    channel: channel,
    child: Builder(builder: (context) {
      final state = StreamChannel.of(context);
      final thread = state.openThread;

      return div([
        div([
          StreamChannelHeader(),
          StreamMessageListView(),
          const StreamTypingIndicator(),
          const StreamMessageInput(),
        ], classes: 'sc-conversation'),
        if (thread != null)
          StreamThreadView(
            key: ValueKey(thread.id),
            parent: thread,
            onClose: state.closeThread,
          ),
      ], classes: 'sc-conversation-split', attributes: {
        'data-thread': thread == null ? 'closed' : 'open',
      });
    }),
  );
}

void drivingTheComposer(BuildContext context, Message message) {
  final composer = StreamChannel.of(context).composer;

  composer.quote(message);
  composer.edit(message);
  composer.text = 'Hello there';
  composer.reset();
}

Component customTheme(StreamChatClient client, Component surface) {
  return StreamChat(
    client: client,
    theme: StreamChatTheme.dark().copyWith(
      primary: const Color('#7c3aed'),
      borderRadius: '8px',
    ),
    child: surface,
  );
}

void main() {
  test('translations fall back to English for anything not overridden', () {
    const german = GermanTranslations();

    expect(german.sendAMessage, 'Nachricht senden');
    expect(german.copyText, const StreamChatTranslations().copyText);
  });
}
