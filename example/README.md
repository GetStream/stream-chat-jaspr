# stream_chat_jaspr example

A two pane chat application built with `stream_chat_jaspr`. The channel list is on the left
and the active conversation on the right. Below 760 px the layout collapses to a single pane
with a back control.

## Running

```bash
dart pub get
dart run tool/dev.dart
```

The application is served at <http://localhost:8080>.

| Flag | Effect |
| --- | --- |
| `--port <n>` | Serve on a different port |
| `--release` | Optimised build (`-O2`) with watching disabled |
| `--no-serve` | Build only |

`tool/dev.dart` replaces `jaspr serve`, which cannot resolve on this SDK. See
[Toolchain constraints](../README.md#toolchain-constraints) in the repository README. The
script compiles with `dart compile js` and rebuilds when any Dart file under `lib/`, `web/`,
or the component library changes.

## Credentials

`lib/demo_credentials.dart` contains two public sandbox accounts, the same credentials used
by the Stream Flutter tutorials.

| Account | Application | Contents |
| --- | --- | --- |
| Sample app user | `s2dxdhpxd94g` | Multiple channels with message history |
| Tutorial user | `b67pax5b2wdq` | A single `flutterdevs` channel |

These tokens are committed intentionally. They belong to Stream's public demo applications
and grant no other access.

In a production application, user tokens must be generated on a server using your API
secret. The secret must never be exposed to the browser. See
[Tokens and authentication](https://getstream.io/chat/docs/dart/tokens_and_authentication/).

## Project structure

| Path | Role |
| --- | --- |
| `web/index.html` | Document shell |
| `web/main.dart` | Client entry point, calls `runApp` |
| `lib/app.dart` | Owns the client lifecycle and the active theme |
| `lib/sign_in_page.dart` | Demo account picker |
| `lib/chat_shell.dart` | Two pane layout and channel selection |
| `lib/app_styles.dart` | Styles for the application shell |
| `lib/demo_credentials.dart` | Sandbox credentials |
| `tool/dev.dart` | Build and serve script |

Styling inside the chat surface comes from `streamChatStyles` in the component library.
`app_styles.dart` covers only the sign in screen and the sidebar header.
