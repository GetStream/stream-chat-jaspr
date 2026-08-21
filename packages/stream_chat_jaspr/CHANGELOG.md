# Changelog

## 0.2.0-dev.1

Brings the component set much closer to the Flutter SDK.

- Message actions: reply in thread, quote, copy, pin, flag, edit, delete, and resend,
  through `StreamMessageActions`. The bar is reachable by keyboard.
- Reactions: `StreamReactionPicker` toggles the current user's reactions, and tiles render
  reaction groups with counts.
- Threads: reply count footers, `StreamThreadView` with its own composer, and an
  "also send to conversation" option. The open thread lives on `StreamChannel`.
- Composer: `StreamMessageComposerController` owns the draft, attachments, quote, and edit
  target. The input autogrows, accepts files by picker, drag and drop, or paste, shows
  per-file upload progress, and offers mention and slash command autocomplete.
- Attachments: `StreamAttachmentList` renders image grids, video, audio, files, giphy, and
  link previews. `StreamImageGallery` adds a full screen viewer with paging and download.
- Search: `StreamMessageSearchController` and `StreamMessageSearchView`.
- Read receipts and delivery state indicators on the message list.
- `StreamChatTranslations` holds every user facing string and is passed through
  `StreamChat(translations: ...)`.
- `StreamPopover` for overlays, with a scrim and escape-to-dismiss.
- Three pane responsive layout, collapsing to two panes below 1100 px and one below 760 px.

## 0.1.0-dev.1

Initial experimental release.

- `StreamChat` and `StreamChannel` scopes providing client/channel down the tree.
- `StreamChannelListController` with pagination and live event handling.
- Components: `StreamChannelListView`, `StreamChannelListTile`, `StreamMessageListView`,
  `StreamMessageTile`, `StreamMessageInput`, `StreamAvatar`, `StreamTypingIndicator`,
  `StreamConnectionStatusBanner`.
- CSS-variable based theming via `StreamChatTheme` and `streamChatStyles`.
