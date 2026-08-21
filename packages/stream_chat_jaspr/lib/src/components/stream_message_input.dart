import 'dart:async';

import 'package:jaspr/dom.dart' hide Filter;
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';
import 'package:universal_web/web.dart' as web;

import '../core/stream_channel.dart';
import '../core/stream_chat.dart';
import '../core/stream_message_composer_controller.dart';
import '../i18n/stream_chat_translations.dart';
import '../util/autocomplete.dart';
import '../util/dom.dart';
import '../util/icons.dart';
import '../util/local_preview.dart';
import 'stream_avatar.dart';

/// The message composer.
///
/// Handles plain text, attachments picked from the file dialog or dropped or
/// pasted onto the composer, quoted replies, editing an existing message,
/// thread replies, and `@` and `/` autocomplete.
///
/// The draft lives in a [StreamMessageComposerController] rather than in this
/// component, so a message action elsewhere in the tree can populate it. See
/// that class for why.
class StreamMessageInput extends StatefulComponent {
  /// Creates a message composer.
  const StreamMessageInput({
    this.placeholder,
    this.sendTypingEvents = true,
    this.enableAttachments = true,
    this.enableAutocomplete = true,
    this.onMessageSent,
    this.onError,
    super.key,
  });

  /// Placeholder shown while the field is empty. Defaults to a translated
  /// string that depends on whether this composer belongs to a thread.
  final String? placeholder;

  /// Whether to emit `typing.start` and `typing.stop` events while composing.
  final bool sendTypingEvents;

  /// Whether to offer the attachment button and accept drops and pastes.
  final bool enableAttachments;

  /// Whether `@` opens the mention popup and `/` the command popup.
  final bool enableAutocomplete;

  /// Called after a message has been accepted by the API.
  final void Function(Message message)? onMessageSent;

  /// Called when sending fails.
  final void Function(Object error)? onError;

  @override
  State<StreamMessageInput> createState() => _StreamMessageInputState();
}

class _StreamMessageInputState extends State<StreamMessageInput> {
  /// Bumped whenever the draft text has to be pushed into the DOM.
  ///
  /// The field is uncontrolled: Jaspr's `textarea` takes its value as a text
  /// child, which maps to `defaultValue` and stops affecting a control the
  /// moment the user types into it. That is exactly what is wanted while
  /// composing, because it leaves the caret alone. It does mean that clearing
  /// after a send, or loading a message for editing, has no effect on its own.
  /// Changing the key discards the element and builds a fresh one from the
  /// current text, which is the one reliable way to reset it without a handle
  /// on the DOM node.
  int _revision = 0;

  bool _isDraggingOver = false;
  AutocompleteQuery? _query;
  List<User> _mentionResults = const [];
  Timer? _mentionDebounce;

  /// Held rather than looked up on demand because [dispose] needs it, and an
  /// inherited lookup is not allowed once the element is being unmounted.
  StreamMessageComposerController? _subscribed;

  StreamMessageComposerController get _composer => _subscribed!;

  Channel get _channel => StreamChannel.of(context).channel;

  StreamChatTranslations get _text => StreamChat.translationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = StreamMessageComposerController.of(context);
    if (identical(controller, _subscribed)) return;
    _subscribed?.removeListener(_onComposerChanged);
    _subscribed = controller..addListener(_onComposerChanged);
    _lastTypedText = controller.text;
  }

  @override
  void dispose() {
    _mentionDebounce?.cancel();
    _subscribed?.removeListener(_onComposerChanged);
    super.dispose();
  }

  /// Rebuilds when the controller changes, and resets the field when the
  /// change came from outside the composer.
  void _onComposerChanged() {
    if (!mounted) return;
    final controller = _subscribed;
    if (controller == null) return;
    // Typing updates the controller from this component, and the text already
    // matches what the DOM holds, so those must not bump the revision or the
    // caret would jump to the end on every keystroke.
    final needsReset = controller.text != _lastTypedText;
    setState(() {
      if (needsReset) {
        _revision++;
        _lastTypedText = controller.text;
        _query = null;
      }
    });
  }

  String _lastTypedText = '';

  void _onInput(web.Event event) {
    final field = event.target as web.HTMLTextAreaElement?;
    if (field == null) return;

    final value = field.value;
    _lastTypedText = value;
    _composer.text = value;
    _autoGrow(field);

    if (component.sendTypingEvents && value.isNotEmpty) {
      // The low level client throttles these internally, so calling on every
      // keystroke is fine.
      _channel.keyStroke(_composer.parentId).ignore();
    }

    if (!component.enableAutocomplete) return;
    final query = detectAutocomplete(value, field.selectionStart);
    if (query != _query) {
      setState(() => _query = query);
      if (query?.kind == AutocompleteKind.mention) _searchMembers(query!.query);
    }
  }

  /// Grows the field with its content up to the height cap set in CSS.
  ///
  /// The height has to be cleared first, otherwise `scrollHeight` is measured
  /// against the previous, larger box and the field can only ever grow.
  void _autoGrow(web.HTMLTextAreaElement field) {
    field.style.height = 'auto';
    field.style.height = '${field.scrollHeight}px';
  }

  void _onKeyDown(web.Event event) {
    final keyEvent = event as web.KeyboardEvent;
    final query = _query;

    if (query != null && _suggestions.isNotEmpty) {
      switch (keyEvent.key) {
        case 'Escape':
          keyEvent.preventDefault();
          setState(() => _query = null);
          return;
        case 'Tab':
        case 'Enter':
          keyEvent.preventDefault();
          _accept(_suggestions.first);
          return;
      }
    }

    if (keyEvent.key == 'Enter' && !keyEvent.shiftKey) {
      keyEvent.preventDefault();
      unawaited(_send());
      return;
    }

    // Escape leaves edit mode, which is the convention in every desktop chat
    // client and avoids stranding the user in a mode with no visible exit.
    if (keyEvent.key == 'Escape' && _composer.isEditing) {
      keyEvent.preventDefault();
      _composer.cancelEdit();
    }
  }

  Future<void> _onPaste(web.Event event) async {
    if (!component.enableAttachments) return;
    final files = filesFromDataTransfer(
      (event as web.ClipboardEvent).clipboardData,
    );
    if (files.isEmpty) return;
    // Only swallow the paste once there is something to attach, so pasting
    // text keeps working normally.
    event.preventDefault();
    await _composer.addFiles(files);
  }

  void _onDragOver(web.Event event) {
    if (!component.enableAttachments) return;
    if (!dragCarriesFiles(event as web.DragEvent)) return;
    // Without this the browser navigates to the dropped file.
    event.preventDefault();
    if (!_isDraggingOver) setState(() => _isDraggingOver = true);
  }

  void _onDragLeave(web.Event event) {
    if (_isDraggingOver) setState(() => _isDraggingOver = false);
  }

  Future<void> _onDrop(web.Event event) async {
    if (!component.enableAttachments) return;
    event.preventDefault();
    if (_isDraggingOver) setState(() => _isDraggingOver = false);
    final files = filesFromDataTransfer((event as web.DragEvent).dataTransfer);
    if (files.isNotEmpty) await _composer.addFiles(files);
  }

  Future<void> _onFilesPicked(web.Event event) async {
    final input = event.target as web.HTMLInputElement?;
    if (input == null) return;
    final files = filesFromInput(input);
    // Clearing lets the same file be picked twice in a row, which otherwise
    // fires no change event the second time.
    input.value = '';
    if (files.isNotEmpty) await _composer.addFiles(files);
  }

  void _searchMembers(String query) {
    _mentionDebounce?.cancel();

    // Local members cover the common case instantly and keep the popup usable
    // while offline. The remote query then fills in anyone not yet loaded.
    final local = [
      for (final member in _channel.state?.members ?? const <Member>[])
        if (member.user case final user? when _matches(user, query)) user,
    ];
    setState(() => _mentionResults = local);

    _mentionDebounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        final response = await _channel.queryMembers(
          filter: query.isEmpty ? null : Filter.autoComplete('name', query),
          pagination: const PaginationParams(limit: 10),
        );
        if (!mounted || _query?.kind != AutocompleteKind.mention) return;
        setState(() {
          _mentionResults = [
            for (final member in response.members) ?member.user,
          ];
        });
      } catch (_) {
        // The local results are already on screen, so a failed lookup just
        // means the list is not extended.
      }
    });
  }

  static bool _matches(User user, String query) {
    if (query.isEmpty) return true;
    final needle = query.toLowerCase();
    return user.name.toLowerCase().contains(needle) ||
        user.id.toLowerCase().contains(needle);
  }

  /// The suggestions currently offered, of whichever kind is active.
  List<Object> get _suggestions {
    final query = _query;
    if (query == null) return const [];
    return switch (query.kind) {
      AutocompleteKind.mention => _mentionResults,
      AutocompleteKind.command => _commandResults(query.query),
    };
  }

  List<Command> _commandResults(String query) {
    final commands = _channel.config?.commands ?? const <Command>[];
    if (query.isEmpty) return commands;
    final needle = query.toLowerCase();
    return [
      for (final command in commands)
        if (command.name.toLowerCase().startsWith(needle)) command,
    ];
  }

  void _accept(Object suggestion) {
    final query = _query;
    if (query == null) return;

    final value = switch (suggestion) {
      User(:final name) => name,
      Command(:final name) => name,
      _ => null,
    };
    if (value == null) return;

    final (text, _) = query.apply(_composer.text, value);
    setState(() {
      _query = null;
      _revision++;
      _lastTypedText = text;
    });
    _composer.text = text;
  }

  Future<void> _send() async {
    final controller = _composer;
    final message = controller.buildMessage();
    // Clearing the controller below is what guards against a double send: a
    // second call finds nothing to build.
    if (message == null) return;

    final isEditing = controller.isEditing;
    // Emptied before the request rather than after it. The client puts the
    // message on screen optimistically, so anything left in the composer would
    // read as a duplicate for however long the upload takes. The snapshot puts
    // it all back if the send is rejected.
    final draft = controller.snapshot();
    controller.reset();
    setState(() {
      _revision++;
      _lastTypedText = '';
      _query = null;
    });

    try {
      final response = isEditing
          ? await _channel.updateMessage(message)
          : await _channel.sendMessage(message);

      if (!mounted) return;
      component.onMessageSent?.call(response.message);

      if (component.sendTypingEvents) {
        _channel.stopTyping(controller.parentId).ignore();
      }
    } catch (error) {
      if (!mounted) return;
      controller.restore(draft);
      setState(() {
        _revision++;
        _lastTypedText = draft.text;
      });
      component.onError?.call(error);
    }
  }

  @override
  Component build(BuildContext context) {
    final controller = _composer;
    final translations = _text;
    final canSend = controller.isNotEmpty;

    return ListenableBuilder(
      listenable: controller,
      builder: (context) {
        return div(
          [
            if (controller.editedMessage != null) _editBanner(translations),
            if (controller.quotedMessage case final quoted?)
              _quoteBanner(quoted, translations),
            if (controller.rejections.isNotEmpty) _rejectionNotice(translations),
            if (controller.attachments.isNotEmpty)
              _attachmentStrip(controller, translations),
            div(
              [
                if (component.enableAttachments) _attachButton(translations),
                textarea(
                  // See [_revision].
                  [Component.text(controller.text)],
                  key: ValueKey('sc-composer-$_revision'),
                  rows: 1,
                  placeholder: component.placeholder ??
                      (controller.isThread
                          ? translations.replyToThread
                          : translations.sendAMessage),
                  classes: 'sc-composer__input',
                  attributes: {
                    'aria-label': component.placeholder ??
                        translations.sendAMessage,
                    'autocomplete': 'off',
                    if (_query != null && _suggestions.isNotEmpty) ...{
                      'aria-expanded': 'true',
                      'aria-controls': 'sc-autocomplete',
                    },
                  },
                  events: {
                    'input': _onInput,
                    'keydown': _onKeyDown,
                    'paste': (event) => unawaited(_onPaste(event)),
                  },
                ),
                button(
                  [
                    if (controller.isEditing)
                      Component.text(translations.saveChanges)
                    else
                      StreamIcons.send(),
                  ],
                  type: ButtonType.button,
                  disabled: !canSend,
                  classes: controller.isEditing
                      ? 'sc-composer__send sc-composer__send--wide'
                      : 'sc-composer__send',
                  attributes: {
                    'aria-label': controller.isEditing
                        ? translations.saveChanges
                        : translations.sendMessageLabel,
                  },
                  onClick: () => unawaited(_send()),
                ),
              ],
              classes: 'sc-composer',
            ),
            if (controller.isThread) _showInChannelToggle(controller),
            if (_query != null && _suggestions.isNotEmpty)
              _autocompletePanel(translations),
            if (_isDraggingOver)
              div(
                [Component.text(translations.dropToAttach)],
                classes: 'sc-composer__dropzone',
              ),
          ],
          classes: _isDraggingOver
              ? 'sc-composer-wrap sc-popover-anchor sc-composer-wrap--dragging'
              : 'sc-composer-wrap sc-popover-anchor',
          events: component.enableAttachments
              ? {
                  'dragover': _onDragOver,
                  'dragleave': _onDragLeave,
                  'drop': (event) => unawaited(_onDrop(event)),
                }
              : null,
        );
      },
    );
  }

  Component _attachButton(StreamChatTranslations translations) {
    return label(
      [
        StreamIcons.paperclip(),
        input(
          type: InputType.file,
          classes: 'sc-visually-hidden',
          attributes: const {'multiple': '', 'tabindex': '-1'},
          events: {'change': (event) => unawaited(_onFilesPicked(event))},
        ),
      ],
      classes: 'sc-composer__attach',
      attributes: {
        'aria-label': translations.attachFilesLabel,
        'title': translations.attachFilesLabel,
      },
    );
  }

  Component _editBanner(StreamChatTranslations translations) {
    return div(
      [
        StreamIcons.pencil(),
        span([Component.text(translations.editingMessage)]),
        button(
          [StreamIcons.close()],
          type: ButtonType.button,
          classes: 'sc-composer__banner-close',
          attributes: {'aria-label': translations.cancelEditLabel},
          onClick: _composer.cancelEdit,
        ),
      ],
      classes: 'sc-composer__banner',
    );
  }

  Component _quoteBanner(Message quoted, StreamChatTranslations translations) {
    final author = quoted.user?.name;
    final preview = (quoted.text ?? '').isNotEmpty
        ? quoted.text!
        : translations.attachment;

    return div(
      [
        StreamIcons.reply(),
        div(
          [
            if (author != null)
              span([Component.text(author)], classes: 'sc-quoted__author'),
            span([Component.text(preview)], classes: 'sc-quoted__text'),
          ],
          classes: 'sc-composer__banner-body',
        ),
        button(
          [StreamIcons.close()],
          type: ButtonType.button,
          classes: 'sc-composer__banner-close',
          attributes: {'aria-label': translations.cancel},
          onClick: _composer.clearQuote,
        ),
      ],
      classes: 'sc-composer__banner',
    );
  }

  Component _rejectionNotice(StreamChatTranslations translations) {
    final limit = translations.fileSize(
      StreamMessageComposerController.maxAttachmentSize,
    );

    return div(
      [
        StreamIcons.alert(),
        span([
          Component.text(
            translations.fileTooLarge(_composer.rejections.join(', '), limit),
          ),
        ]),
        button(
          [StreamIcons.close()],
          type: ButtonType.button,
          classes: 'sc-composer__banner-close',
          attributes: {'aria-label': translations.cancel},
          onClick: _composer.clearRejections,
        ),
      ],
      classes: 'sc-composer__banner sc-composer__banner--error',
      attributes: const {'role': 'alert'},
    );
  }

  Component _attachmentStrip(
    StreamMessageComposerController controller,
    StreamChatTranslations translations,
  ) {
    return div(
      [
        for (final attachment in controller.attachments)
          div(
            [
              if (previewUrlFor(attachment) case final url?
                  when attachment.type == AttachmentType.image)
                img(
                  src: url,
                  alt: attachment.title ?? translations.attachment,
                  classes: 'sc-composer__thumb-image',
                )
              else
                div(
                  [
                    StreamIcons.file(),
                    span([
                      Component.text(
                        attachment.title ?? translations.attachment,
                      ),
                    ]),
                  ],
                  classes: 'sc-composer__thumb-file',
                ),
              button(
                [StreamIcons.close()],
                type: ButtonType.button,
                classes: 'sc-composer__thumb-remove',
                attributes: {
                  'aria-label': translations.removeAttachment(
                    attachment.title ?? translations.attachment,
                  ),
                },
                onClick: () => controller.removeAttachment(attachment.id),
              ),
            ],
            key: ValueKey(attachment.id),
            classes: 'sc-composer__thumb',
          ),
      ],
      classes: 'sc-composer__thumbs',
    );
  }

  Component _showInChannelToggle(StreamMessageComposerController controller) {
    return label(
      [
        input(
          type: InputType.checkbox,
          value: controller.showInChannel ? 'on' : '',
          attributes: {if (controller.showInChannel) 'checked': ''},
          events: {
            'change': (event) {
              final box = event.target as web.HTMLInputElement?;
              controller.showInChannel = box?.checked ?? false;
            },
          },
        ),
        span([
          Component.text(StreamChat.translationsOf(context).alsoSendToChannel),
        ]),
      ],
      classes: 'sc-composer__show-in-channel',
    );
  }

  Component _autocompletePanel(StreamChatTranslations translations) {
    final query = _query!;
    final suggestions = _suggestions;

    return div(
      [
        div(
          [
            Component.text(
              query.kind == AutocompleteKind.mention
                  ? translations.mentionsHeading
                  : translations.commandsHeading,
            ),
          ],
          classes: 'sc-autocomplete__heading',
        ),
        for (final suggestion in suggestions.take(8))
          button(
            switch (suggestion) {
              final User user => [
                  StreamAvatar.user(user, size: 24),
                  span([Component.text(user.name)]),
                ],
              final Command command => [
                  span(
                    [Component.text('/${command.name}')],
                    classes: 'sc-autocomplete__command',
                  ),
                  span(
                    [Component.text(command.description)],
                    classes: 'sc-autocomplete__description',
                  ),
                ],
              _ => const <Component>[],
            },
            type: ButtonType.button,
            classes: 'sc-autocomplete__option',
            attributes: const {'role': 'option'},
            onClick: () => _accept(suggestion),
          ),
      ],
      id: 'sc-autocomplete',
      classes: 'sc-autocomplete',
      attributes: const {'role': 'listbox'},
    );
  }
}
