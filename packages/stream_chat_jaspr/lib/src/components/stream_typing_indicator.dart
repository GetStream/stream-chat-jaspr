import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../core/stream_chat.dart';
import '../core/stream_channel.dart';

/// Shows who is currently typing in the surrounding [StreamChannel].
///
/// Always occupies its line height, even when nobody is typing, so the message
/// list does not jump as the indicator appears and disappears.
class StreamTypingIndicator extends StatelessComponent {
  /// Creates a typing indicator.
  const StreamTypingIndicator({super.key});

  @override
  Component build(BuildContext context) {
    final channel = StreamChannel.of(context).channel;
    final currentUserId = StreamChat.of(context).currentUser?.id;

    return StreamBuilder<Map<User, Event>>(
      stream: channel.state?.typingEventsStream,
      initialData: const {},
      builder: (context, snapshot) {
        final users = (snapshot.data ?? const <User, Event>{})
            .keys
            .where((it) => it.id != currentUserId)
            .toList();

        return div(
          [
            if (users.isNotEmpty) ...[
              div(
                [span([]), span([]), span([])],
                classes: 'sc-typing__dots',
                attributes: const {'aria-hidden': 'true'},
              ),
              Component.text(_label(context, users)),
            ],
          ],
          classes: 'sc-typing',
          attributes: const {'aria-live': 'polite'},
        );
      },
    );
  }

  String _label(BuildContext context, List<User> users) {
    final translations = StreamChat.translationsOf(context);
    return switch (users.length) {
      0 => '',
      1 => translations.typingSingle(users.first.name),
      _ => translations.typingMultiple([for (final user in users) user.name]),
    };
  }
}
