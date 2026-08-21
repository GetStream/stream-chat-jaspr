import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../core/stream_chat.dart';
import '../i18n/stream_chat_translations.dart';
import '../util/icons.dart';
import '../util/local_preview.dart';
import 'stream_image_gallery.dart';

/// Renders the attachments on a message.
///
/// Images and GIFs are collected into a grid so that a multi-image message
/// reads as one unit, and everything else is rendered in place below it.
/// Clicking any image opens [StreamImageGallery] over the whole set.
///
/// Attachments that are still uploading are rendered from their in-memory
/// bytes with a progress overlay, which is what makes a picked image appear
/// immediately rather than after the round trip.
class StreamAttachmentList extends StatefulComponent {
  /// Creates an attachment list.
  const StreamAttachmentList({
    required this.attachments,
    this.onRetryUpload,
    super.key,
  });

  /// The attachments to render, in message order.
  final List<Attachment> attachments;

  /// Called with the attachment id when a failed upload should be retried.
  final void Function(String attachmentId)? onRetryUpload;

  @override
  State<StreamAttachmentList> createState() => _StreamAttachmentListState();
}

class _StreamAttachmentListState extends State<StreamAttachmentList> {
  int? _galleryIndex;

  /// Attachments that belong in the image grid.
  List<Attachment> get _images => [
        for (final attachment in component.attachments)
          if (_isImageLike(attachment)) attachment,
      ];

  static bool _isImageLike(Attachment attachment) {
    if (attachment.type == AttachmentType.urlPreview) return false;
    if (attachment.ogScrapeUrl != null) return false;
    return attachment.type == AttachmentType.image ||
        attachment.type == AttachmentType.giphy;
  }

  @override
  Component build(BuildContext context) {
    final translations = StreamChat.translationsOf(context);
    final images = _images;
    final others = [
      for (final attachment in component.attachments)
        if (!_isImageLike(attachment)) attachment,
    ];

    return div(
      [
        if (images.isNotEmpty)
          div(
            [
              for (var i = 0; i < images.length; i++)
                _imageTile(images[i], i, translations),
            ],
            classes: images.length == 1
                ? 'sc-attachment-grid sc-attachment-grid--single'
                : 'sc-attachment-grid',
          ),
        for (final attachment in others) _other(attachment, translations),
        if (_galleryIndex case final index?)
          StreamImageGallery(
            attachments: images,
            initialIndex: index,
            onClose: () => setState(() => _galleryIndex = null),
          ),
      ],
      classes: 'sc-attachments',
    );
  }

  Component _imageTile(
    Attachment attachment,
    int index,
    StreamChatTranslations translations,
  ) {
    final url = previewUrlFor(attachment);
    final state = attachment.uploadState;

    return button(
      [
        if (url != null)
          img(
            src: url,
            alt: attachment.title ?? translations.attachment,
            classes: 'sc-attachment-grid__image',
            attributes: const {'loading': 'lazy'},
          )
        else
          div([StreamIcons.file()], classes: 'sc-attachment-grid__placeholder'),
        ?_uploadOverlay(state, attachment, translations),
      ],
      type: ButtonType.button,
      classes: 'sc-attachment-grid__cell',
      // Hold the space the image will occupy. An `img` has no size until its
      // bytes arrive, so without this the cell collapses to nothing and the
      // attachment appears to be missing until it pops in at full height.
      styles: Styles(raw: {'aspect-ratio': _aspectRatioFor(attachment)}),
      attributes: {
        'aria-label': attachment.title ?? translations.attachment,
        // An image that has not finished uploading has no remote URL yet, so
        // there is nothing for the gallery to show at full size.
        if (!state.isSuccess) 'disabled': '',
      },
      onClick: () {
        if (!state.isSuccess) return;
        setState(() => _galleryIndex = index);
      },
    );
  }

  /// The shape to reserve for [attachment] before its image has loaded.
  ///
  /// Stream returns the source dimensions for uploads it has processed, which
  /// gives an exact box and so no reflow at all. Anything else, including an
  /// upload still in flight, gets a neutral landscape box.
  static String _aspectRatioFor(Attachment attachment) {
    final width = attachment.originalWidth;
    final height = attachment.originalHeight;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return '4 / 3';
    }

    // Very tall images would otherwise take over the whole conversation.
    final ratio = width / height;
    if (ratio < 0.6) return '3 / 5';
    return '$width / $height';
  }

  Component _other(Attachment attachment, StreamChatTranslations translations) {
    if (attachment.type == AttachmentType.urlPreview ||
        attachment.ogScrapeUrl != null) {
      return _linkPreview(attachment, translations);
    }
    if (attachment.type == AttachmentType.video) {
      return _video(attachment, translations);
    }
    if (attachment.type == AttachmentType.audio ||
        attachment.type == AttachmentType.voiceRecording) {
      return _audio(attachment, translations);
    }
    return _file(attachment, translations);
  }

  Component _linkPreview(
    Attachment attachment,
    StreamChatTranslations translations,
  ) {
    final url = attachment.ogScrapeUrl ?? attachment.titleLink;
    final image = attachment.imageUrl ?? attachment.thumbUrl;

    final card = div(
      [
        if (image != null)
          img(
            src: image,
            alt: '',
            classes: 'sc-link-preview__image',
            attributes: const {'loading': 'lazy', 'aria-hidden': 'true'},
          ),
        div(
          [
            if (attachment.authorName case final author?)
              span([Component.text(author)], classes: 'sc-link-preview__author'),
            if (attachment.title case final title?)
              span([Component.text(title)], classes: 'sc-link-preview__title'),
            if (attachment.text case final text?)
              span([Component.text(text)], classes: 'sc-link-preview__text'),
          ],
          classes: 'sc-link-preview__body',
        ),
      ],
      classes: 'sc-link-preview',
    );

    if (url == null) return card;
    return a(
      [card],
      href: url,
      target: Target.blank,
      classes: 'sc-link-preview__anchor',
      attributes: const {'rel': 'noopener noreferrer'},
    );
  }

  Component _video(Attachment attachment, StreamChatTranslations translations) {
    final url = attachment.assetUrl ?? previewUrlFor(attachment);
    if (url == null) return _file(attachment, translations);

    return video(
      [],
      src: url,
      controls: true,
      preload: Preload.metadata,
      poster: attachment.thumbUrl,
      classes: 'sc-attachment-video',
      attributes: {'aria-label': attachment.title ?? translations.attachment},
    );
  }

  Component _audio(Attachment attachment, StreamChatTranslations translations) {
    final url = attachment.assetUrl ?? previewUrlFor(attachment);
    if (url == null) return _file(attachment, translations);

    return div(
      [
        if (attachment.title case final title?)
          span([Component.text(title)], classes: 'sc-attachment-audio__title'),
        audio(
          [],
          src: url,
          controls: true,
          preload: Preload.metadata,
          classes: 'sc-attachment-audio__player',
        ),
      ],
      classes: 'sc-attachment-audio',
    );
  }

  Component _file(Attachment attachment, StreamChatTranslations translations) {
    final url = attachment.assetUrl;
    final title = attachment.title ?? attachment.fallback ?? translations.attachment;
    final size = attachment.fileSize ?? attachment.file?.size;
    final state = attachment.uploadState;

    final body = [
      StreamIcons.file(),
      div(
        [
          span([Component.text(title)], classes: 'sc-attachment-file__name'),
          if (size != null)
            span(
              [Component.text(translations.fileSize(size))],
              classes: 'sc-attachment-file__meta',
            ),
        ],
        classes: 'sc-attachment-file__body',
      ),
      ?_uploadOverlay(state, attachment, translations),
    ];

    if (url == null || !state.isSuccess) {
      return div(body, classes: 'sc-attachment-file');
    }
    return a(
      body,
      href: url,
      target: Target.blank,
      classes: 'sc-attachment-file',
      attributes: const {'rel': 'noopener noreferrer'},
    );
  }

  /// The progress bar or failure notice drawn over an attachment mid-upload.
  ///
  /// Returns `null` for a finished upload, which is the common case, so that
  /// nothing extra is added to the DOM for messages from the server.
  Component? _uploadOverlay(
    UploadState state,
    Attachment attachment,
    StreamChatTranslations translations,
  ) {
    if (state.isSuccess) return null;

    if (state.isFailed) {
      return div(
        [
          StreamIcons.alert(),
          span([Component.text(translations.uploadFailed)]),
          if (component.onRetryUpload case final retry?)
            button(
              [Component.text(translations.retry)],
              type: ButtonType.button,
              classes: 'sc-button sc-button--ghost',
              onClick: () => retry(attachment.id),
            ),
        ],
        classes: 'sc-attachment-overlay sc-attachment-overlay--failed',
      );
    }

    final fraction = switch (state) {
      InProgress(:final uploaded, :final total) when total > 0 =>
        uploaded / total,
      _ => null,
    };

    return div(
      [
        div(
          [
            div(
              [],
              classes: 'sc-progress__fill',
              styles: Styles(
                raw: {
                  if (fraction != null)
                    'width': '${(fraction * 100).clamp(0, 100).round()}%',
                },
              ),
            ),
          ],
          classes: fraction == null
              ? 'sc-progress sc-progress--indeterminate'
              : 'sc-progress',
          attributes: {
            'role': 'progressbar',
            if (fraction != null)
              'aria-valuenow': '${(fraction * 100).round()}',
          },
        ),
      ],
      classes: 'sc-attachment-overlay',
    );
  }
}
