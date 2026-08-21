# stream_chat_jaspr example

A two-pane chat client — channel list on the left, conversation on the right — built with
`stream_chat_jaspr`. Collapses to a single pane below 760px.

## Run

```bash
dart pub get
dart run tool/dev.dart
```

Then open <http://localhost:8080> and pick one of the demo accounts.

| Flag | Effect |
| --- | --- |
| `--port 3000` | Serve on a different port |
| `--release` | Optimised build (`-O2`), no watching |
| `--no-serve` | Build only |

`tool/dev.dart` stands in for `jaspr serve`, which cannot resolve on this SDK — see the
[repository README](../README.md#toolchain-constraint). It compiles with `dart compile js`
and rebuilds when anything under `lib/`, `web/`, or the SDK package changes.

## Credentials

`lib/demo_credentials.dart` holds two public sandbox accounts, the same ones used by the
Stream Flutter tutorials. The tokens are committed on purpose: they belong to Stream's demo
apps and grant access to nothing else.

A real app must mint user tokens on a server with its API secret. The secret must never
reach the browser.

## Structure

| File | Role |
| --- | --- |
| `web/main.dart` | Client entrypoint, calls `runApp` |
| `lib/app.dart` | Owns the client lifecycle and theme |
| `lib/sign_in_page.dart` | Demo account picker |
| `lib/chat_shell.dart` | Two-pane layout and channel selection |
| `lib/app_styles.dart` | Styles for the app's own chrome |
| `tool/dev.dart` | Build-and-serve script |
