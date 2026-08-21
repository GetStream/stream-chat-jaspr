import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';
import 'package:universal_web/web.dart' as web;

import '../util/dom.dart';
import '../util/local_preview.dart';

/// Everything the composer is currently holding: draft text, attachments, and
/// whether it is quoting, editing, or replying in a thread.
///
/// This is the counterpart of `StreamMessageInputController` in the Flutter
/// SDK. It exists as a separate object rather than state inside the input
/// component because other components drive it: the action menu on a message
/// calls [quote] and [edit], and a thread pane owns its own instance so that
/// the draft in a thread survives switching back and forth to the main
/// conversation.
///
/// Obtain the one for the surrounding scope with
/// [StreamMessageComposerController.of].
class StreamMessageComposerController extends ChangeNotifier {
  /// Creates a controller.
  ///
  /// Pass [parentId] to compose replies inside a thread.
  StreamMessageComposerController({this.parentId});

  /// The message this composer replies under, when it belongs to a thread.
  final String? parentId;

  /// Largest file accepted by [addFiles], in bytes.
  ///
  /// Matches the default limit on a Stream application. Uploading more than
  /// this fails server side, so it is worth rejecting early with a clear
  /// message rather than after a long upload.
  static const maxAttachmentSize = 100 * 1024 * 1024;

  String _text = '';
  Message? _quotedMessage;
  Message? _editedMessage;
  bool _showInChannel = false;
  final List<Attachment> _attachments = [];
  final List<String> _rejections = [];

  /// The current draft text.
  String get text => _text;

  set text(String value) {
    if (_text == value) return;
    _text = value;
    notifyListeners();
  }

  /// The message being quoted, if any.
  Message? get quotedMessage => _quotedMessage;

  /// The message being edited, if any.
  Message? get editedMessage => _editedMessage;

  /// Whether a thread reply should also appear in the main conversation.
  bool get showInChannel => _showInChannel;

  set showInChannel(bool value) {
    if (_showInChannel == value) return;
    _showInChannel = value;
    notifyListeners();
  }

  /// Attachments staged for the next send, in the order they were added.
  List<Attachment> get attachments => List.unmodifiable(_attachments);

  /// Files that were rejected by [addFiles], for example for being too large.
  ///
  /// Cleared by [clearRejections] once they have been shown.
  List<String> get rejections => List.unmodifiable(_rejections);

  /// Whether there is anything worth sending.
  bool get isNotEmpty => _text.trim().isNotEmpty || _attachments.isNotEmpty;

  /// Whether the composer is in edit mode.
  bool get isEditing => _editedMessage != null;

  /// Whether the composer belongs to a thread.
  bool get isThread => parentId != null;

  /// Quotes [message] in the next send.
  ///
  /// Quoting while editing cancels the edit, because a message cannot both
  /// replace an existing one and quote another.
  void quote(Message message) {
    _editedMessage = null;
    _quotedMessage = message;
    notifyListeners();
  }

  /// Drops the quoted message.
  void clearQuote() {
    if (_quotedMessage == null) return;
    _quotedMessage = null;
    notifyListeners();
  }

  /// Loads [message] into the composer for editing.
  void edit(Message message) {
    _quotedMessage = null;
    _editedMessage = message;
    _text = message.text ?? '';
    _attachments
      ..clear()
      ..addAll(message.attachments);
    notifyListeners();
  }

  /// Leaves edit mode and clears the draft.
  void cancelEdit() {
    if (_editedMessage == null) return;
    _editedMessage = null;
    _clearDraft();
    notifyListeners();
  }

  /// Stages [files] as attachments.
  ///
  /// Files are held in memory and uploaded by the channel as part of
  /// [sendMessage], which is also what reports per-attachment progress. Files
  /// over [maxAttachmentSize] are rejected and reported through [rejections].
  Future<void> addFiles(Iterable<web.File> files) async {
    var changed = false;

    for (final file in files) {
      if (file.size > maxAttachmentSize) {
        _rejections.add(file.name);
        changed = true;
        continue;
      }

      final bytes = await readFileBytes(file);
      _attachments.add(
        Attachment(
          type: _attachmentTypeFor(file.type).rawType,
          file: AttachmentFile(
            size: file.size,
            name: file.name,
            bytes: bytes,
          ),
          // Preserved so the composer can show a size and the tile can pick an
          // icon before anything has been uploaded.
          extraData: {'file_size': file.size, 'mime_type': file.type},
        ),
      );
      changed = true;
    }

    if (changed) notifyListeners();
  }

  /// Removes a staged attachment.
  void removeAttachment(String attachmentId) {
    final before = _attachments.length;
    _attachments.removeWhere((it) => it.id == attachmentId);
    if (_attachments.length == before) return;
    releaseLocalPreview(attachmentId);
    notifyListeners();
  }

  /// Forgets any rejected files that have already been surfaced.
  void clearRejections() {
    if (_rejections.isEmpty) return;
    _rejections.clear();
    notifyListeners();
  }

  /// Builds the message described by the current state, or `null` if there is
  /// nothing to send.
  ///
  /// In edit mode this returns the edited message with its new text and
  /// attachments, so it can be handed straight to `channel.updateMessage`.
  Message? buildMessage() {
    if (!isNotEmpty) return null;
    final text = _text.trim();

    final edited = _editedMessage;
    if (edited != null) {
      return edited.copyWith(text: text, attachments: [..._attachments]);
    }

    return Message(
      text: text,
      attachments: [..._attachments],
      parentId: parentId,
      showInChannel: parentId != null && _showInChannel ? true : null,
      quotedMessageId: _quotedMessage?.id,
    );
  }

  /// Clears everything except [parentId].
  void reset() {
    _editedMessage = null;
    _quotedMessage = null;
    _showInChannel = false;
    _clearDraft(releasePreviews: false);
    notifyListeners();
  }

  /// Captures the current draft so it can be put back by [restore].
  ///
  /// Sending clears the composer immediately rather than when the request
  /// completes, because an upload can take seconds and leaving the attachment
  /// in the composer while it also appears on the pending message reads as a
  /// duplicate. The snapshot is what makes that safe: if the send fails, the
  /// draft goes back exactly as it was.
  StreamComposerDraft snapshot() {
    return StreamComposerDraft._(
      text: _text,
      attachments: [..._attachments],
      quotedMessage: _quotedMessage,
      editedMessage: _editedMessage,
      showInChannel: _showInChannel,
    );
  }

  /// Puts back a draft captured by [snapshot].
  void restore(StreamComposerDraft draft) {
    _text = draft._text;
    _attachments
      ..clear()
      ..addAll(draft._attachments);
    _quotedMessage = draft._quotedMessage;
    _editedMessage = draft._editedMessage;
    _showInChannel = draft._showInChannel;
    notifyListeners();
  }

  /// Clears the text and attachments.
  ///
  /// Previews are only released when the attachments are being discarded for
  /// good. After a send the same bytes are still on screen underneath the
  /// pending message, so revoking the blob URL would blank it out.
  void _clearDraft({bool releasePreviews = true}) {
    _text = '';
    if (releasePreviews) {
      for (final attachment in _attachments) {
        releaseLocalPreview(attachment.id);
      }
    }
    _attachments.clear();
  }

  /// Maps a browser MIME type onto the attachment types Stream understands.
  ///
  /// Stream keys rendering and moderation off this, and it decides whether the
  /// upload goes to the image endpoint or the file endpoint.
  static AttachmentType _attachmentTypeFor(String mimeType) {
    if (mimeType.startsWith('image/')) return AttachmentType.image;
    if (mimeType.startsWith('video/')) return AttachmentType.video;
    if (mimeType.startsWith('audio/')) return AttachmentType.audio;
    return AttachmentType.file;
  }

  /// The controller provided by the closest [StreamComposerScope].
  ///
  /// Throws when there is none, which means the component is outside both a
  /// [StreamChannel] and a thread pane.
  static StreamMessageComposerController of(BuildContext context) {
    final controller = maybeOf(context);
    if (controller == null) {
      throw StateError(
        'No StreamComposerScope ancestor found.\n'
        'StreamChannel installs one automatically, so this usually means the '
        'component is mounted outside of a StreamChannel.',
      );
    }
    return controller;
  }

  /// The controller provided by the closest [StreamComposerScope], or `null`.
  static StreamMessageComposerController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<StreamComposerScope>()
        ?.controller;
  }

  @override
  void dispose() {
    _clearDraft();
    super.dispose();
  }
}

/// A captured composer draft, returned by
/// [StreamMessageComposerController.snapshot].
class StreamComposerDraft {
  const StreamComposerDraft._({
    required String text,
    required List<Attachment> attachments,
    required Message? quotedMessage,
    required Message? editedMessage,
    required bool showInChannel,
  })  : _text = text,
        _attachments = attachments,
        _quotedMessage = quotedMessage,
        _editedMessage = editedMessage,
        _showInChannel = showInChannel;

  final String _text;
  final List<Attachment> _attachments;
  final Message? _quotedMessage;
  final Message? _editedMessage;
  final bool _showInChannel;

  /// The captured draft text.
  String get text => _text;
}

/// Carries a [StreamMessageComposerController] down the tree.
///
/// [StreamChannel] installs one for the main conversation. A thread pane
/// installs a second one, which shadows the first for everything inside it so
/// that the two drafts stay independent.
class StreamComposerScope extends InheritedComponent {
  /// Creates the scope.
  const StreamComposerScope({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The controller being provided.
  final StreamMessageComposerController controller;

  @override
  bool updateShouldNotify(StreamComposerScope oldComponent) =>
      controller != oldComponent.controller;
}
