# Stream Chat for Jaspr (experimental)

An experimental port of the [Stream Chat Flutter SDK](https://github.com/GetStream/stream-chat-flutter)
UI layer to [Jaspr](https://jaspr.site), Dart's web framework. It renders a working chat
client as real DOM — no canvas, no Flutter engine, no `.wasm` payload.

Verified working against Stream's public demo apps: channel list with live previews and
unread badges, message history with pagination, sending, reactions, typing indicators,
read state, light/dark theming, and a responsive two-pane layout.

![The example app in the light theme](docs/light.png)

![The example app in the dark theme](docs/dark.png)

## Is a Jaspr SDK possible?

Yes, and the reason is that Stream already did the hard part. The `stream_chat` package is
**pure Dart** — no Flutter import anywhere in its tree — and it already ships conditional
imports for the web (`platform_detector_web.dart`, `web_socket_channel`). It runs unmodified
in a browser under `dart compile js`.

That means the port is genuinely a *UI-layer-only* problem. The split looks like this:

| Flutter SDK package | Jaspr equivalent | Effort |
| --- | --- | --- |
| `stream_chat` | **reused as-is** | none |
| `stream_chat_flutter_core` | reimplemented, much smaller | moderate |
| `stream_chat_flutter` | reimplemented as DOM components | the actual work |
| `stream_chat_persistence` | not ported (Drift/SQLite is not a browser story) | — |
| `stream_chat_localizations` | not ported | — |

Because `stream_chat` is re-exported from `stream_chat_jaspr`, everything you know from the
low level client — `Channel`, `Message`, `Filter`, `client.on(...)` — works identically.

## Repository layout

```
packages/stream_chat_jaspr/   the SDK
example/                      a two-pane chat client using it
```

## Running the example

```bash
cd example
dart pub get
dart run tool/dev.dart          # http://localhost:8080
```

Pick one of the two public demo accounts on the sign-in screen. Both belong to Stream's
sandbox apps and are the same credentials the Flutter tutorials use.

## Using the package

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

`StreamChat` injects the stylesheet and the theme's CSS variables for you. Pass
`injectStyles: false` if you would rather render `Style(styles: streamChatStyles)` once at
the document level.

### What's included

**Scopes** — `StreamChat` (client + theme), `StreamChannel` (watches a channel and provides it).

**State** — `StreamChannelListController`, a `ChangeNotifier` with pagination and live event
handling.

**Components** — `StreamChannelListView`, `StreamChannelListTile`, `StreamChannelHeader`,
`StreamMessageListView`, `StreamMessageTile`, `StreamMessageInput`, `StreamAvatar`,
`StreamTypingIndicator`, `StreamConnectionStatusBanner`.

**Theming** — `StreamChatTheme` (light/dark + `copyWith`) compiled to CSS custom properties.

### What's not included

This is a feasibility spike, not a replacement for the Flutter SDK. Missing, roughly in the
order I would add it:

- Attachment **uploads** (rendering of existing image/file attachments works)
- Threads and quoted replies
- Adding/removing reactions (existing ones render and are clickable, but no picker)
- Message actions: edit, delete, pin, flag, mute, copy
- Slash commands, `@` mentions, autocomplete
- Polls, drafts, reminders, location sharing, AI streaming responses
- Offline persistence
- Localisation — user-facing strings are hardcoded English in `src/util/formatting.dart`
- Message search, member/user lists
- Anything requiring a context menu or modal

## Design notes

A few decisions worth knowing about, because they differ from the Flutter SDK.

**The message list scrolls with CSS, not code.** `.sc-message-list` is
`flex-direction: column-reverse`. Browsers anchor scrolling to the visual bottom of a
reversed flex container, so a new message keeps the viewport pinned and a user who has
scrolled up stays put — no `ScrollController`, no imperative `jumpTo`. The cost is that
children must be emitted newest-first, which `StreamMessageListView` does by building the
list in natural order and reversing at the end.

**Theming is CSS variables, not an inherited component.** `StreamChatTheme.cssVariables` is
applied once to the root element and every rule in the stylesheet resolves through
`var(--sc-*)`. Swapping themes updates one element's style attribute instead of rebuilding
the subtree.

**No `jaspr_builder` codegen.** No `@client`, `@css`, or `@Import` annotations anywhere. The
stylesheet is a plain `List<StyleRule>` rendered through Jaspr's `Style` component, which
means consumers need no build step — and, as it turns out, that is also what makes the
project buildable at all right now (see below).

**`is` checks don't work on interop types.** `package:web` types are extension types, erased
at runtime, so `event.target is Element` is *always true* and checks nothing — the analyzer
flags it as `invalid_runtime_check_with_js_interop_types`. Event handlers here cast with
`as` instead, which is safe because a scroll event's target is always the bound element.
Using `isA<T>()` would be stricter but requires `dart:js_interop`, which does not exist on
the VM and would make the package uncompilable for server-side rendering.

**No app-lifecycle handling.** `StreamChatCore` in the Flutter SDK disconnects after a
keep-alive window when the app is backgrounded, because mobile OSes suspend apps and kill
sockets. Browsers keep websockets open in background tabs and the low level client already
reconnects with backoff, so there is no equivalent here.

## Toolchain constraint

**`jaspr serve` cannot be used on Dart 3.13.** `jaspr_web_compilers` is pinned to
`>=3.7.0 <3.11.0-z`, and `stream_chat` 10.1+ requires `^3.11.0`. Those ranges do not
intersect, so the standard `build_runner` pipeline cannot resolve alongside a current
`stream_chat`.

This turns out not to matter, because the app uses no Jaspr codegen. `example/tool/dev.dart`
compiles with `dart compile js` and serves the result with `shelf`, including watch-and-
rebuild:

```bash
dart run tool/dev.dart                # build, serve, rebuild on change
dart run tool/dev.dart --release      # optimised build
dart run tool/dev.dart --port 3000
```

Once `jaspr_web_compilers` supports the current SDK, that script can be deleted in favour of
`jaspr serve`. The alternative today would be pinning `stream_chat` to 10.0.0 (the last
release accepting Dart <3.11), which would work but keeps you a version behind.

## Verification

```bash
cd packages/stream_chat_jaspr && dart analyze && dart test   # 33 tests
cd example && dart analyze && dart run tool/dev.dart --no-serve
```

Beyond the unit and component tests, the browser behaviour was checked end to end by driving
headless Chrome over the DevTools Protocol: sign in, load 20 channels, open one, paginate
history from 25 to 50 messages, type with real key events, send with Enter, and confirm the
bubble appears and the composer clears — with zero console errors.

## Versions

Built against Dart 3.13.1, `jaspr` 0.23.4, and `stream_chat` 10.3.0.
