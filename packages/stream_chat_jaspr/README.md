# stream_chat_jaspr

Chat UI components for [Jaspr](https://jaspr.site), built on the official
[Stream Chat Dart client](https://pub.dev/packages/stream_chat).

The package is a presentation layer only. Networking, event handling, and channel state are
provided by `stream_chat`, which is re-exported here so a single import covers both.

> **Status: experimental.** Several core chat features are not implemented. Refer to the
> [repository README](../../README.md) for the full feature coverage matrix, implementation
> notes, and toolchain constraints.

## Requirements

| Dependency | Version |
| --- | --- |
| Dart SDK | 3.11 or later |
| `jaspr` | 0.23.4 |
| `stream_chat` | 10.3.0 |

## Installation

```yaml
dependencies:
  stream_chat_jaspr:
    path: ../packages/stream_chat_jaspr
```

The package is not published to pub.dev.

## Usage

Wrap your chat surface in a `StreamChat` scope to provide the client and theme, then wrap
individual conversations in a `StreamChannel` scope.

```dart
import 'package:jaspr/dom.dart' hide Filter; // stream_chat also exports a Filter
import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';

final client = StreamChatClient('your-api-key');
await client.connectUser(User(id: 'jane'), tokenFromYourBackend);

StreamChat(
  client: client,
  child: StreamChannel(
    channel: client.channel('messaging', id: 'general'),
    child: Component.fragment([
      StreamChannelHeader(),
      StreamMessageListView(),
      StreamTypingIndicator(),
      StreamMessageInput(),
    ]),
  ),
);
```

`StreamChat` injects the stylesheet and the theme's CSS custom properties. Pass
`injectStyles: false` to render `Style(styles: streamChatStyles)` yourself.

User tokens must be generated on a server using your API secret. Never ship the secret to
the browser.

### Channel lists

`StreamChannelListView` creates and owns a `StreamChannelListController` unless one is
supplied. Pagination is driven by the scroll position of the list.

```dart
StreamChannelListView(
  filter: Filter.in_('members', [client.state.currentUser!.id]),
  selectedChannelCid: selected?.cid,
  onChannelTap: (channel) => setState(() => selected = channel),
);
```

To share a controller across components, or to trigger a refresh from elsewhere, construct
one directly:

```dart
final controller = StreamChannelListController(client: client, limit: 30);
await controller.refresh();

StreamChannelListView(controller: controller);
```

## API reference

### Scopes

| Component | Responsibility |
| --- | --- |
| `StreamChat` | Provides the client and theme, injects the stylesheet |
| `StreamChannel` | Watches a channel and provides it to descendants |

Both expose `of(context)` and `maybeOf(context)` accessors.

### State

| Type | Responsibility |
| --- | --- |
| `StreamChannelListController` | Pages through `queryChannels` and applies live events |

### UI

| Component | Description |
| --- | --- |
| `StreamChannelListView` | Scrollable, paginated channel list |
| `StreamChannelListTile` | Channel row with avatar, preview, and unread badge |
| `StreamChannelHeader` | Title bar with avatar, member count, and presence |
| `StreamMessageListView` | Message history with grouping and date separators |
| `StreamMessageTile` | Single message with bubble, attachments, and reactions |
| `StreamMessageInput` | Plain text composer that emits typing events |
| `StreamAvatar` | Circular avatar with deterministic initials fallback |
| `StreamTypingIndicator` | Live "user is typing" line |
| `StreamConnectionStatusBanner` | Banner shown while reconnecting or offline |

### Theming

| Type | Description |
| --- | --- |
| `StreamChatTheme` | Design tokens with `light()`, `dark()`, and `copyWith()` |
| `streamChatStyles` | The component stylesheet as `List<StyleRule>` |

## Theming

Theme tokens are compiled to CSS custom properties and applied to the root element. Every
rule in the stylesheet resolves through those variables.

```dart
StreamChat(
  client: client,
  theme: StreamChatTheme.dark().copyWith(
    primary: const Color('#7c3aed'),
    borderRadius: '8px',
  ),
  child: myChatSurface,
);
```

For changes the tokens do not cover, target the `sc-` prefixed classes directly. They are
defined in `lib/src/theme/stream_chat_styles.dart`.

## Testing

```bash
dart analyze
dart test
```

Component tests use `jaspr_test`. Components that do not require a connected client, such as
`StreamAvatar` and `StreamMessageTile`, can be pumped directly.
