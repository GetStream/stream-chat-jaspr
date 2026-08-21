/// Experimental Jaspr components for Stream Chat.
///
/// Layered the same way as the Flutter SDK: the pure-Dart `stream_chat` client
/// does all the networking and state, and this package only renders it. The
/// whole `stream_chat` surface is re-exported, so a single import is enough.
///
/// ```dart
/// import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';
///
/// final client = StreamChatClient('your-api-key');
/// await client.connectUser(User(id: 'jane'), token);
///
/// // ...
/// StreamChat(
///   client: client,
///   child: StreamChannel(
///     channel: client.channel('messaging', id: 'general'),
///     child: div([
///       StreamChannelHeader(),
///       StreamMessageListView(),
///       StreamTypingIndicator(),
///       StreamMessageInput(),
///     ], classes: 'sc-channel-pane'),
///   ),
/// )
/// ```
library;

export 'package:stream_chat/stream_chat.dart';

export 'src/components/stream_avatar.dart';
export 'src/components/stream_channel_header.dart';
export 'src/components/stream_channel_list_tile.dart';
export 'src/components/stream_channel_list_view.dart';
export 'src/components/stream_connection_status_banner.dart';
export 'src/components/stream_message_input.dart';
export 'src/components/stream_message_list_view.dart';
export 'src/components/stream_message_tile.dart';
export 'src/components/stream_typing_indicator.dart';
export 'src/core/stream_channel.dart';
export 'src/core/stream_channel_list_controller.dart';
export 'src/core/stream_chat.dart';
export 'src/theme/stream_chat_styles.dart';
export 'src/theme/stream_chat_theme.dart';
export 'src/util/channel_display.dart';
export 'src/util/formatting.dart';
