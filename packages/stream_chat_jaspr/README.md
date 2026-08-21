# stream_chat_jaspr

Experimental [Jaspr](https://jaspr.site) components for [Stream Chat](https://getstream.io/chat/).

Built on the pure-Dart `stream_chat` client, which runs unmodified in the browser. This
package only handles rendering — it adds no networking or state of its own beyond a small
paginating controller for channel lists.

See the [repository README](../../README.md) for the full picture: what is and isn't
implemented, design notes, and the toolchain caveat around `jaspr serve`.

## Install

```yaml
dependencies:
  stream_chat_jaspr:
    path: ../packages/stream_chat_jaspr
```

## Use

```dart
import 'package:jaspr/dom.dart' hide Filter; // stream_chat also exports a Filter
import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';

final client = StreamChatClient('your-api-key');
await client.connectUser(User(id: 'jane'), tokenFromYourBackend);

StreamChat(
  client: client,
  child: div([
    StreamChannelListView(
      onChannelTap: (channel) { /* ... */ },
    ),
  ], classes: 'sc-channel-list-pane'),
);
```

`stream_chat` is re-exported, so one import covers both.

## API

| Type | Purpose |
| --- | --- |
| `StreamChat` | Provides the client and theme; injects the stylesheet |
| `StreamChannel` | Watches a channel and provides it to descendants |
| `StreamChannelListController` | `ChangeNotifier` with pagination and live events |
| `StreamChannelListView` | Scrollable, paginated channel list |
| `StreamChannelListTile` | One channel row: avatar, preview, unread badge |
| `StreamChannelHeader` | Title bar with avatar and presence |
| `StreamMessageListView` | Message history with grouping and date dividers |
| `StreamMessageTile` | One message: bubble, attachments, reactions |
| `StreamMessageInput` | Plain-text composer with typing events |
| `StreamAvatar` | Circular avatar with deterministic initials fallback |
| `StreamTypingIndicator` | "X is typing…" line |
| `StreamConnectionStatusBanner` | Offline/reconnecting banner |
| `StreamChatTheme` | Design tokens, compiled to CSS custom properties |
| `streamChatStyles` | The component stylesheet as `List<StyleRule>` |

## Styling

Every colour resolves through CSS custom properties emitted by the theme, so you can
override any token without touching the stylesheet:

```dart
StreamChat(
  client: client,
  theme: StreamChatTheme.dark().copyWith(
    primary: const Color('#7c3aed'),
    borderRadius: '8px',
  ),
  child: /* ... */,
);
```

To restyle beyond the tokens, target the `sc-` classes directly — they are stable and
documented by `lib/src/theme/stream_chat_styles.dart`.
