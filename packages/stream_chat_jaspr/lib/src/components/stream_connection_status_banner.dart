import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../core/stream_chat.dart';

/// A banner that appears while the websocket is reconnecting or offline.
///
/// Renders nothing at all when the connection is healthy, so it can be placed
/// unconditionally at the top of a chat surface.
class StreamConnectionStatusBanner extends StatelessComponent {
  /// Creates a connection status banner.
  const StreamConnectionStatusBanner({super.key});

  @override
  Component build(BuildContext context) {
    final chat = StreamChat.of(context);

    return StreamBuilder<ConnectionStatus>(
      stream: chat.connectionStatusStream,
      initialData: chat.client.wsConnectionStatus,
      builder: (context, snapshot) {
        return switch (snapshot.data) {
          ConnectionStatus.connecting => div(
              [Component.text('Reconnecting…')],
              classes: 'sc-connection-banner sc-connection-banner--connecting',
            ),
          ConnectionStatus.disconnected => div(
              [Component.text('You are offline')],
              classes: 'sc-connection-banner',
            ),
          _ => Component.empty(),
        };
      },
    );
  }
}
