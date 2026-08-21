import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../core/stream_chat.dart';
import '../core/stream_channel.dart';
import '../util/channel_display.dart';
import 'stream_avatar.dart';

/// Header bar for the surrounding [StreamChannel]: avatar, title, and presence.
class StreamChannelHeader extends StatelessComponent {
  /// Creates a channel header.
  const StreamChannelHeader({this.leading, this.trailing, super.key});

  /// Rendered before the avatar. Typically a back button on narrow layouts.
  final Component? leading;

  /// Rendered at the end of the bar.
  final Component? trailing;

  @override
  Component build(BuildContext context) {
    final channel = StreamChannel.of(context).channel;
    final currentUserId = StreamChat.of(context).currentUser?.id;

    return StreamBuilder<ChannelState>(
      stream: channel.state?.channelStateStream,
      builder: (context, _) {
        return div(
          [
            ?leading,
            StreamAvatar.channel(
              channel,
              currentUserId: currentUserId,
              size: 36,
            ),
            div(
              [
                div(
                  [Component.text(
                    channelDisplayName(channel, currentUserId: currentUserId),
                  )],
                  classes: 'sc-channel-header__title',
                ),
                div(
                  [Component.text(_subtitle(context, channel, currentUserId))],
                  classes: 'sc-channel-header__subtitle',
                ),
              ],
              styles: const Styles(raw: {'flex': '1 1 auto', 'min-width': '0'}),
            ),
            ?trailing,
          ],
          classes: 'sc-channel-header',
        );
      },
    );
  }

  String _subtitle(
    BuildContext context,
    Channel channel,
    String? currentUserId,
  ) {
    final translations = StreamChat.translationsOf(context);
    final members = channel.state?.members ?? const <Member>[];
    final others = members.where((it) => it.userId != currentUserId).toList();

    if (others.length == 1) {
      final user = others.first.user;
      if (user == null) return '';
      if (user.online) return translations.online;
      final lastActive = user.lastActive;
      if (lastActive == null) return translations.offline;
      return translations.lastSeen(_ago(lastActive));
    }

    final onlineCount = others.where((it) => it.user?.online ?? false).length;
    final memberLabel = translations.memberCount(members.length);
    if (onlineCount == 0) return memberLabel;
    return '$memberLabel, $onlineCount ${translations.online.toLowerCase()}';
  }

  String _ago(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
