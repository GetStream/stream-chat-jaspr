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
  });
}
