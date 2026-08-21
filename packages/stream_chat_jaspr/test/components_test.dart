import 'package:jaspr/dom.dart' hide Filter;
import 'package:jaspr_test/jaspr_test.dart';
import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';

/// jaspr_test has no class-based finder, so match on the rendered elements.
Finder byClass(String className) {
  bool hasClass(String? classes) =>
      classes != null && classes.split(RegExp(r'\s+')).contains(className);

  return find.byComponentPredicate(
    (component) => switch (component) {
      div(classes: final classes) => hasClass(classes),
      button(classes: final classes) => hasClass(classes),
      span(classes: final classes) => hasClass(classes),
      a(classes: final classes) => hasClass(classes),
      img(classes: final classes) => hasClass(classes),
      code(classes: final classes) => hasClass(classes),
      _ => false,
    },
    description: 'component with class "$className"',
  );
}

void main() {
  final alice = User(id: 'alice', name: 'Alice Anderson');
  final bob = User(id: 'bob', name: 'Bob Brown');

  group('StreamAvatar', () {
    testComponents('renders initials when there is no image', (tester) async {
      tester.pumpComponent(StreamAvatar.user(alice));
      expect(find.text('AA'), findsOneComponent);
    });

    testComponents('renders an image when one is provided', (tester) async {
      tester.pumpComponent(
        StreamAvatar.user(
          User(id: 'carol', name: 'Carol', image: 'https://example.com/c.png'),
        ),
      );
      expect(find.text('C'), findsNothing);
      expect(find.tag('img'), findsOneComponent);
    });

    testComponents('omits the presence dot when offline', (tester) async {
      tester.pumpComponent(StreamAvatar.user(alice, showPresence: true));
      expect(byClass('sc-avatar__presence'), findsNothing);
    });
  });

  group('StreamMessageTile', () {
    testComponents('renders the message text', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(text: 'Hello there', user: bob),
          isOwn: false,
        ),
      );
      expect(find.text('Hello there'), findsOneComponent);
    });

    testComponents('shows the author for incoming messages', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(text: 'Hi', user: bob),
          isOwn: false,
        ),
      );
      expect(find.text('Bob Brown'), findsOneComponent);
    });

    testComponents('hides the author for own messages', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(text: 'Hi', user: alice),
          isOwn: true,
        ),
      );
      expect(find.text('Alice Anderson'), findsNothing);
    });

    testComponents('renders a placeholder for deleted messages',
        (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(
            text: 'gone',
            user: bob,
            type: MessageType.deleted,
          ),
          isOwn: false,
        ),
      );
      expect(find.text('This message was deleted'), findsOneComponent);
      expect(find.text('gone'), findsNothing);
    });

    testComponents('renders reaction chips with their counts', (tester) async {
      final now = DateTime.now();
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(
            text: 'Nice',
            user: bob,
            reactionGroups: {
              'like': ReactionGroup(
                count: 3,
                sumScores: 3,
                firstReactionAt: now,
                lastReactionAt: now,
              ),
            },
          ),
          isOwn: false,
        ),
      );
      expect(find.text('3'), findsOneComponent);
      expect(byClass('sc-reaction'), findsOneComponent);
    });

    testComponents('marks the current user\'s own reaction', (tester) async {
      final now = DateTime.now();
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(
            text: 'Nice',
            user: bob,
            ownReactions: [Reaction(type: 'like', userId: 'alice')],
            reactionGroups: {
              'like': ReactionGroup(
                count: 1,
                sumScores: 1,
                firstReactionAt: now,
                lastReactionAt: now,
              ),
            },
          ),
          isOwn: false,
        ),
      );
      expect(byClass('sc-reaction--own'), findsOneComponent);
    });

    testComponents('renders a quoted message above the text', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(
            text: 'I agree',
            user: alice,
            quotedMessage: Message(text: 'The original point', user: bob),
          ),
          isOwn: true,
        ),
      );
      expect(byClass('sc-quoted'), findsOneComponent);
      expect(find.text('The original point'), findsOneComponent);
    });

    testComponents('shows a reply count that opens the thread', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(text: 'Question', user: bob, replyCount: 4),
          isOwn: false,
        ),
      );
      expect(find.text('4 replies'), findsOneComponent);
    });

    testComponents('uses the singular form for one reply', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(text: 'Question', user: bob, replyCount: 1),
          isOwn: false,
        ),
      );
      expect(find.text('1 reply'), findsOneComponent);
    });

    testComponents('hides the thread footer when there are no replies',
        (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(text: 'Statement', user: bob),
          isOwn: false,
        ),
      );
      expect(byClass('sc-thread-footer'), findsNothing);
    });

    testComponents('marks an edited message', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(
            text: 'Fixed typo',
            user: bob,
            messageTextUpdatedAt: DateTime.now(),
          ),
          isOwn: false,
        ),
      );
      expect(find.text('edited'), findsOneComponent);
    });

    testComponents('renders a link as an anchor', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(text: 'see https://example.com', user: bob),
          isOwn: false,
        ),
      );
      expect(byClass('sc-link'), findsOneComponent);
    });

    testComponents('highlights a mention of a known user', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(
            text: 'ping @alice',
            user: bob,
            mentionedUsers: [alice],
          ),
          isOwn: false,
        ),
      );
      expect(byClass('sc-mention'), findsOneComponent);
    });

    testComponents('shows a pinned marker', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(text: 'Read this', user: bob, pinned: true),
          isOwn: false,
        ),
      );
      expect(byClass('sc-message-pinned'), findsOneComponent);
    });

    testComponents('omits actions on a deleted message', (tester) async {
      tester.pumpComponent(
        StreamMessageTile(
          message: Message(text: 'x', user: bob, type: MessageType.deleted),
          isOwn: false,
        ),
      );
      expect(byClass('sc-message-actions'), findsNothing);
    });
  });

  group('StreamAttachmentList', () {
    testComponents('puts images in a grid', (tester) async {
      tester.pumpComponent(
        StreamAttachmentList(
          attachments: [
            Attachment(
              type: 'image',
              imageUrl: 'https://example.com/a.png',
              uploadState: const UploadState.success(),
            ),
            Attachment(
              type: 'image',
              imageUrl: 'https://example.com/b.png',
              uploadState: const UploadState.success(),
            ),
          ],
        ),
      );
      expect(byClass('sc-attachment-grid'), findsOneComponent);
      expect(byClass('sc-attachment-grid__cell'), findsNComponents(2));
    });

    testComponents('renders a file attachment outside the grid',
        (tester) async {
      tester.pumpComponent(
        StreamAttachmentList(
          attachments: [
            Attachment(
              type: 'file',
              title: 'report.pdf',
              assetUrl: 'https://example.com/report.pdf',
              uploadState: const UploadState.success(),
            ),
          ],
        ),
      );
      expect(byClass('sc-attachment-grid'), findsNothing);
      expect(find.text('report.pdf'), findsOneComponent);
    });

    testComponents('renders a link preview for an enriched url',
        (tester) async {
      tester.pumpComponent(
        StreamAttachmentList(
          attachments: [
            Attachment(
              type: 'image',
              ogScrapeUrl: 'https://example.com/article',
              title: 'An article',
              uploadState: const UploadState.success(),
            ),
          ],
        ),
      );
      expect(byClass('sc-link-preview'), findsOneComponent);
      expect(byClass('sc-attachment-grid'), findsNothing);
    });

    testComponents('shows a progress overlay while uploading', (tester) async {
      tester.pumpComponent(
        StreamAttachmentList(
          attachments: [
            Attachment(
              type: 'image',
              imageUrl: 'https://example.com/a.png',
              uploadState: const UploadState.inProgress(
                uploaded: 50,
                total: 100,
              ),
            ),
          ],
        ),
      );
      expect(byClass('sc-attachment-overlay'), findsOneComponent);
    });

    testComponents('shows a failure notice for a failed upload',
        (tester) async {
      tester.pumpComponent(
        StreamAttachmentList(
          attachments: [
            Attachment(
              type: 'file',
              title: 'big.zip',
              uploadState: const UploadState.failed(error: 'too large'),
            ),
          ],
        ),
      );
      expect(find.text('Upload failed'), findsOneComponent);
    });
  });

  group('StreamReactionPicker', () {
    testComponents('offers every default reaction', (tester) async {
      tester.pumpComponent(
        StreamReactionPicker(onSelected: (_) {}),
      );
      expect(
        byClass('sc-reaction-picker__option'),
        findsNComponents(defaultReactionEmoji.length),
      );
    });

    testComponents('marks reactions the user has already left', (tester) async {
      tester.pumpComponent(
        StreamReactionPicker(onSelected: (_) {}, ownReactions: const {'love'}),
      );
      expect(
        byClass('sc-reaction-picker__option--own'),
        findsOneComponent,
      );
    });

    testComponents('reports the chosen reaction', (tester) async {
      String? chosen;
      tester.pumpComponent(
        StreamReactionPicker(
          onSelected: (type) => chosen = type,
          types: const {'like': '+1'},
        ),
      );

      await tester.click(byClass('sc-reaction-picker__option'));
      expect(chosen, 'like');
    });
  });
}
