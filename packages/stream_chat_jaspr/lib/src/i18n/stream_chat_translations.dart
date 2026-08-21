/// Every user-facing string rendered by this package.
///
/// The Flutter SDK ships translations as a separate `stream_chat_localizations`
/// package built on `flutter_localizations` and ARB files. Neither exists for
/// Jaspr, so strings live here instead as overridable members on a plain class.
/// Subclass it, override the members you want, and hand the result to
/// [StreamChat.translations].
///
/// ```dart
/// class DutchTranslations extends StreamChatTranslations {
///   const DutchTranslations();
///
///   @override
///   String get sendAMessage => 'Stuur een bericht';
/// }
/// ```
///
/// Members that depend on a value are methods rather than getters so that
/// languages with different plural or word-order rules can restructure the
/// sentence completely instead of interpolating into a fixed template.
class StreamChatTranslations {
  /// Creates the default English translations.
  const StreamChatTranslations();

  // ------------------------------------------------------------- composer --

  /// Placeholder in the message composer.
  String get sendAMessage => 'Send a message';

  /// Placeholder in the composer while replying inside a thread.
  String get replyToThread => 'Reply to thread';

  /// Accessible label of the send button.
  String get sendMessageLabel => 'Send message';

  /// Accessible label of the attachment button.
  String get attachFilesLabel => 'Attach files';

  /// Accessible label of the emoji button.
  String get addReactionLabel => 'Add reaction';

  /// Accessible label of the button that cancels editing.
  String get cancelEditLabel => 'Cancel editing';

  /// Shown above the composer while a message is being edited.
  String get editingMessage => 'Editing message';

  /// Label of the button that confirms an edit.
  String get saveChanges => 'Save';

  /// Hint shown while a file is dragged over the composer.
  String get dropToAttach => 'Drop files to attach them';

  // ------------------------------------------------------------- messages --

  /// Body of a message that has been deleted.
  String get messageDeleted => 'This message was deleted';

  /// Marker appended to a message whose text was changed after sending.
  String get edited => 'edited';

  /// Shown on a message that failed to send.
  String get messageFailed => 'Message failed to send';

  /// Label of the control that retries a failed message.
  String get retry => 'Retry';

  /// Empty state of the message list.
  String get noMessagesYet => 'No messages yet. Say hello.';

  /// Empty state of the channel list.
  String get noChannels => 'No conversations yet.';

  /// Empty state shown when no channel has been selected.
  String get selectAConversation => 'Select a conversation to start chatting.';

  /// Divider label for messages sent today.
  String get today => 'Today';

  /// Divider label for messages sent yesterday.
  String get yesterday => 'Yesterday';

  /// Separator between the pinned marker and the pinning user.
  String pinnedBy(String name) => 'Pinned by $name';

  /// Label of the divider marking the first unread message.
  String get newMessages => 'New';

  /// Accessible label of the control that scrolls back to the newest message.
  String get jumpToLatest => 'Jump to latest messages';

  /// Shown when the channel list could not be loaded.
  String loadChannelsFailed(Object error) => 'Could not load channels: $error';

  // -------------------------------------------------------------- actions --

  /// Opens the message action menu.
  String get messageActionsLabel => 'Message actions';

  /// Action that starts a thread on a message.
  String get replyInThread => 'Reply in thread';

  /// Action that quotes a message in the composer.
  String get quoteMessage => 'Quote message';

  /// Action that edits a message.
  String get editMessage => 'Edit message';

  /// Action that copies the message text to the clipboard.
  String get copyText => 'Copy text';

  /// Action that pins a message to the channel.
  String get pinMessage => 'Pin to conversation';

  /// Action that removes a pin.
  String get unpinMessage => 'Unpin from conversation';

  /// Action that flags a message for moderation.
  String get flagMessage => 'Flag message';

  /// Action that deletes a message.
  String get deleteMessage => 'Delete message';

  /// Confirmation prompt shown before deleting.
  String get deleteMessageConfirmation =>
      'Delete this message? This cannot be undone.';

  /// Generic confirm label.
  String get confirm => 'Delete';

  /// Generic cancel label.
  String get cancel => 'Cancel';

  /// Confirmation shown after a message has been flagged.
  String get messageFlagged => 'Message flagged for review.';

  /// Shown when an action on a message could not be completed.
  ///
  /// [action] is the label of the action that failed, so one string covers
  /// every entry in the menu.
  String actionFailed(String action) => 'Could not complete: $action';

  /// Shown when the browser refuses a clipboard write.
  String get copyFailed => 'Could not copy to the clipboard.';

  // ------------------------------------------------------------- threads --

  /// Title of the thread pane.
  String get thread => 'Thread';

  /// Accessible label of the control that closes the thread pane.
  String get closeThread => 'Close thread';

  /// Footer on a message that has replies.
  String replyCount(int count) => count == 1 ? '1 reply' : '$count replies';

  /// Divider between the parent message and its replies.
  String get startOfThread => 'Start of thread';

  /// Label of the option that copies a thread reply into the conversation.
  String get alsoSendToChannel => 'Also send to conversation';

  // ------------------------------------------------------------- presence --

  /// Line shown while a single user is typing.
  String typingSingle(String name) => '$name is typing';

  /// Line shown while several users are typing.
  String typingMultiple(List<String> names) {
    if (names.length == 2) return '${names.first} and ${names.last} are typing';
    return '${names.length} people are typing';
  }

  /// Subtitle of a channel header for a group conversation.
  String memberCount(int count) => count == 1 ? '1 member' : '$count members';

  /// Subtitle of a channel header when the other user is online.
  String get online => 'Online';

  /// Subtitle of a channel header when the other user was last seen.
  String lastSeen(String relative) => 'Last seen $relative';

  /// Banner shown while the client is re-establishing its connection.
  String get reconnecting => 'Reconnecting';

  /// Banner shown while the client is offline.
  String get offline => 'Offline. Messages will send when you reconnect.';

  /// Summary of who has read a message.
  String readBy(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return 'Read by ${names.single}';
    if (names.length == 2) return 'Read by ${names.first} and ${names.last}';
    return 'Read by ${names.first} and ${names.length - 1} others';
  }

  /// Accessible label describing a message that has been sent but not read.
  String get deliveredLabel => 'Sent';

  /// Accessible label describing a message that is still in flight.
  String get sendingLabel => 'Sending';

  // -------------------------------------------------------------- search --

  /// Placeholder of the message search field.
  String get searchMessages => 'Search messages';

  /// Empty state of the search results list.
  String get noSearchResults => 'No messages found.';

  /// Accessible label of the control that clears the search field.
  String get clearSearch => 'Clear search';

  // --------------------------------------------------------- attachments --

  /// Fallback title for an attachment with no name.
  String get attachment => 'Attachment';

  /// Accessible label of the control that removes a pending attachment.
  String removeAttachment(String name) => 'Remove $name';

  /// Shown on an attachment whose upload failed.
  String get uploadFailed => 'Upload failed';

  /// Accessible label of the control that closes the image viewer.
  String get closeImageViewer => 'Close image';

  /// Accessible label of the control showing the previous image.
  String get previousImage => 'Previous image';

  /// Accessible label of the control showing the next image.
  String get nextImage => 'Next image';

  /// Rejection message for a file above the size limit.
  String fileTooLarge(String name, String limit) =>
      '$name is larger than the $limit upload limit.';

  /// Human readable file size.
  String fileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final rounded = size >= 10 || unit == 0
        ? size.round().toString()
        : size.toStringAsFixed(1);
    return '$rounded ${units[unit]}';
  }

  // --------------------------------------------------- mentions, commands --

  /// Heading of the mention autocomplete popup.
  String get mentionsHeading => 'People';

  /// Heading of the slash command autocomplete popup.
  String get commandsHeading => 'Commands';
}
