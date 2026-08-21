# Stream Chat for Jaspr

Chat UI components for [Jaspr](https://jaspr.site), built on the official
[Stream Chat Dart client](https://pub.dev/packages/stream_chat).

This project brings the component model of the
[Stream Chat Flutter SDK](https://github.com/GetStream/stream-chat-flutter) to the web as
plain DOM. There is no canvas renderer, no Flutter engine, and no WebAssembly payload. The
release build of the example application is 0.7 MB of JavaScript.

> **Status: experimental.** This is a feasibility study, not a supported product. The API
> surface is small, several core chat features are missing, and breaking changes should be
> expected. See [Feature coverage](#feature-coverage) before adopting it.

![The example application in the light theme](docs/light.png)

![The example application in the dark theme](docs/dark.png)

## Overview

The Stream Chat Dart client is a pure Dart package. It has no dependency on Flutter and
already ships conditional imports for the browser, including a web platform detector and a
web socket transport. It compiles and runs unmodified under `dart compile js`.

As a result, porting the SDK to Jaspr is a presentation layer exercise. Networking, event
handling, offline reconciliation, and channel state are all reused from the existing client.

| Flutter SDK package | Status in this project |
| --- | --- |
| `stream_chat` | Reused without modification |
| `stream_chat_flutter_core` | Reimplemented, reduced scope |
| `stream_chat_flutter` | Reimplemented as DOM components |
| `stream_chat_persistence` | Not ported. Drift and SQLite are not browser targets |
| `stream_chat_localizations` | Not ported |

`stream_chat_jaspr` re-exports `stream_chat`, so `Channel`, `Message`, `Filter`,
`client.on(...)`, and the rest of the low level API are available from a single import and
behave exactly as they do in the Flutter SDK.

## Repository layout

| Path | Contents |
| --- | --- |
| `packages/stream_chat_jaspr` | The component library |
| `example` | A two pane chat application built with the library |
| `docs` | Screenshots used by this document |

## Requirements

| Dependency | Version |
| --- | --- |
| Dart SDK | 3.11 or later (developed against 3.13.1) |
| `jaspr` | 0.23.4 |
| `stream_chat` | 10.3.0 |

## Installation

```yaml
dependencies:
  stream_chat_jaspr:
    path: packages/stream_chat_jaspr
```

The package is not published to pub.dev.

## Quick start

```dart
import 'package:jaspr/dom.dart' hide Filter; // stream_chat also exports a Filter
import 'package:stream_chat_jaspr/stream_chat_jaspr.dart';

final client = StreamChatClient('your-api-key');
await client.connectUser(User(id: 'jane'), tokenFromYourBackend);

StreamChat(
  client: client,
  theme: StreamChatTheme.dark(),
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

`StreamChat` injects the stylesheet and the active theme's CSS custom properties. Pass
`injectStyles: false` to render `Style(styles: streamChatStyles)` yourself, for example once
at the document level rather than once per chat surface.

User tokens must be generated on a server using your API secret. Never ship the secret to
the browser.

## Components

### Scopes

| Component | Responsibility |
| --- | --- |
| `StreamChat` | Provides the client and theme to the subtree, injects the stylesheet |
| `StreamChannel` | Watches a channel and provides it to descendants |

### State

| Type | Responsibility |
| --- | --- |
| `StreamChannelListController` | A `ChangeNotifier` that pages through `queryChannels` and applies live events |

### UI

| Component | Description |
| --- | --- |
| `StreamChannelListView` | Scrollable, paginated channel list |
| `StreamChannelListTile` | Channel row with avatar, last message preview, unread badge |
| `StreamChannelHeader` | Title bar with avatar, member count, and presence |
| `StreamMessageListView` | Message history with author grouping and date separators |
| `StreamMessageTile` | Single message with bubble, attachments, and reactions |
| `StreamMessageInput` | Plain text composer that emits typing events |
| `StreamAvatar` | Circular avatar with a deterministic initials fallback |
| `StreamTypingIndicator` | Live "user is typing" line |
| `StreamConnectionStatusBanner` | Banner shown while reconnecting or offline |

## Theming

`StreamChatTheme` is compiled to CSS custom properties and applied once to the root element.
Every rule in the stylesheet resolves through those variables, so changing a theme updates a
single style attribute instead of rebuilding the component tree.

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

`StreamChatTheme.light()` and `StreamChatTheme.dark()` are provided. For changes that the
tokens do not cover, target the `sc-` prefixed classes directly. They are defined in
`packages/stream_chat_jaspr/lib/src/theme/stream_chat_styles.dart`.

## Running the example

```bash
cd example
dart pub get
dart run tool/dev.dart
```

The application is served at <http://localhost:8080>. The sign in screen offers two public
sandbox accounts, the same credentials used by the Stream Flutter tutorials.

See [`example/README.md`](example/README.md) for additional options.

## Feature coverage

### Supported

- Channel list with pagination, live previews, and unread counts
- Message history with pagination, author grouping, and date separators
- Sending plain text messages
- Rendering image and file attachments
- Rendering reaction groups with counts and own reaction state
- Typing indicators
- Read state and unread counts
- Connection status reporting
- Deleted, failed, and pending message states
- Light and dark themes
- Responsive two pane layout that collapses below 760 px

### Not supported

- Attachment uploads
- Threads and quoted replies
- Adding and removing reactions, including the reaction picker
- Message actions such as edit, delete, pin, flag, and mute
- Slash commands, mentions, and autocomplete
- Polls, drafts, reminders, location sharing, and AI streaming responses
- Offline persistence
- Localization. User facing strings are hardcoded in English in
  `packages/stream_chat_jaspr/lib/src/util/formatting.dart`
- Message search, member lists, and user lists
- Context menus and modal dialogs

## Implementation notes

These decisions differ from the Flutter SDK and are relevant when reading or extending the
code.

### Scroll anchoring is handled by CSS

`.sc-message-list` uses `flex-direction: column-reverse`. Browsers anchor scrolling to the
visual bottom of a reversed flex container, so appending a message keeps the viewport pinned
while a user who has scrolled up stays in place. No scroll controller or imperative scroll
call is required. The trade off is that children are emitted newest first, so
`StreamMessageListView` builds the list in chronological order and reverses it before
rendering.

### Theming uses CSS custom properties

The Flutter SDK resolves theme values from the widget tree on every build. This package
emits `StreamChatTheme.cssVariables` onto the root element once and resolves colours through
`var(--sc-*)` in the stylesheet.

### No code generation

The package uses no `jaspr_builder` annotations. There are no `@client`, `@css`, or
`@Import` directives. The stylesheet is a `List<StyleRule>` rendered through Jaspr's `Style`
component, so consumers require no build step. This also keeps the project buildable on the
current SDK, as described in [Toolchain constraints](#toolchain-constraints).

### Type checks against JS interop types

`package:web` types are extension types and are erased at runtime. An expression such as
`event.target is Element` evaluates to `true` unconditionally and checks nothing. The
analyzer reports this as `invalid_runtime_check_with_js_interop_types`.

Event handlers in this package narrow with `as` instead, which is correct because the target
of a scroll event is always the element the handler is bound to. The stricter alternative,
`isA<T>()`, requires `dart:js_interop`, which is unavailable on the Dart VM and would
prevent the package from compiling for server side rendering.

### No application lifecycle handling

`StreamChatCore` in the Flutter SDK disconnects the socket after a keep alive window when
the application is backgrounded, because mobile operating systems suspend applications and
close sockets. Browsers keep web sockets open in background tabs, and the Dart client
already reconnects with backoff, so this package has no equivalent behaviour.

## Toolchain constraints

`jaspr serve` cannot be used on Dart 3.11 or later. `jaspr_web_compilers` declares a
constraint of `>=3.7.0 <3.11.0-z`, while `stream_chat` 10.1 and later require `^3.11.0`.
The two ranges do not intersect, so the standard `build_runner` pipeline cannot resolve
alongside a current Stream Chat client.

Because the project uses no code generation, this has no effect on the output.
`example/tool/dev.dart` compiles with `dart compile js` and serves the result with `shelf`:

```bash
dart run tool/dev.dart                # build, serve, and rebuild on change
dart run tool/dev.dart --release      # optimised build
dart run tool/dev.dart --port 3000    # serve on a different port
```

Two paths remove the constraint. Pinning `stream_chat` to 10.0.0, the last release that
accepts Dart below 3.11, restores `jaspr serve` at the cost of staying one version behind.
Alternatively, once `jaspr_web_compilers` supports the current SDK, `tool/dev.dart` can be
deleted in favour of `jaspr serve`.

## Development

```bash
# Component library
cd packages/stream_chat_jaspr
dart pub get
dart analyze
dart test

# Example application
cd example
dart pub get
dart analyze
dart run tool/dev.dart --no-serve
```

The library ships 33 tests covering the formatting utilities, channel and message preview
logic, and the components that render without a connected client.

Browser behaviour was verified against Stream's public demo application by driving headless
Chrome over the DevTools Protocol: sign in, load 20 channels, open a channel, page history
from 25 to 50 messages, enter text using synthesised key events, send with the Enter key,
and confirm that the message renders and the composer clears. The run completed with no
console errors.
