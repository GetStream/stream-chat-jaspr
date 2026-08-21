import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../core/stream_chat.dart';
import '../util/channel_display.dart';
import '../util/formatting.dart';
import 'stream_avatar.dart';

/// A single row in a [StreamChannelListView].
///
/// Subscribes to its own channel's state stream, so a new message or a read
/// event only re-renders this tile rather than the whole list.
class StreamChannelListTile extends StatelessComponent {
  /// Creates a channel tile.
  const StreamChannelListTile({
    required this.channel,
    this.selected = false,
    this.onTap,
    super.key,
  });

  /// The channel to render.
  final Channel channel;

  /// Whether this tile is the currently open channel.
  final bool selected;

  /// Called when the tile is activated.
  final void Function(Channel channel)? onTap;

  @override
  Component build(BuildContext context) {
    final currentUserId = StreamChat.of(context).currentUser?.id;

    return StreamBuilder<ChannelState>(
      stream: channel.state?.channelStateStream,
      builder: (context, _) => _buildTile(context, currentUserId),
    );
  }

  Component _buildTile(BuildContext context, String? currentUserId) {
    final state = channel.state;
    final lastMessage = state?.lastMessage;
    final unread = state?.unreadCount ?? 0;
    final timestamp = lastMessage?.createdAt ?? channel.lastMessageAt;

    return button(
      [
        StreamAvatar.channel(channel, currentUserId: currentUserId),
        div(
          [
            div(
              [
                span(
                  [Component.text(
                    channelDisplayName(channel, currentUserId: currentUserId),
                  )],
                  classes: 'sc-channel-tile__name',
                ),
                if (timestamp != null)
                  span(
                    [
                      Component.text(
                        formatChannelTimestamp(
                          timestamp,
                          yesterday:
                              StreamChat.translationsOf(context).yesterday,
                        ),
                      ),
                    ],
                    classes: 'sc-channel-tile__time',
                  ),
              ],
              classes: 'sc-channel-tile__row',
            ),
            div(
              [
                span(
                  [Component.text(
                    messagePreview(lastMessage, currentUserId: currentUserId),
                  )],
                  classes: 'sc-channel-tile__preview',
                ),
                if (unread > 0)
                  span(
                    [Component.text(unread > 99 ? '99+' : '$unread')],
                    classes: 'sc-badge',
                  ),
              ],
              classes: 'sc-channel-tile__row',
            ),
          ],
          classes: 'sc-channel-tile__body',
        ),
      ],
      classes: 'sc-channel-tile',
      attributes: {'aria-selected': '$selected'},
      onClick: () => onTap?.call(channel),
    );
  }
}
