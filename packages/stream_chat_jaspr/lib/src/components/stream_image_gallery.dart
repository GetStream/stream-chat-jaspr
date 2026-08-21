import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../core/stream_chat.dart';
import '../util/dom.dart';
import '../util/icons.dart';
import '../util/local_preview.dart';

/// A full-viewport viewer for the images on a message.
///
/// The Flutter SDK routes to a dedicated `StreamMediaGalleryPage`. On the web
/// a route change would put the gallery in the browser history, so closing it
/// with the back button would leave the conversation instead. Rendering it as
/// an overlay keeps the URL and scroll position untouched.
class StreamImageGallery extends StatefulComponent {
  /// Creates a gallery over [attachments], opening at [initialIndex].
  const StreamImageGallery({
    required this.attachments,
    required this.onClose,
    this.initialIndex = 0,
    super.key,
  });

  /// The images to page through.
  final List<Attachment> attachments;

  /// Called when the viewer should close.
  final void Function() onClose;

  /// Index of the image shown first.
  final int initialIndex;

  @override
  State<StreamImageGallery> createState() => _StreamImageGalleryState();
}

class _StreamImageGalleryState extends State<StreamImageGallery> {
  late int _index = component.initialIndex;
  void Function()? _removeEscapeListener;

  @override
  void initState() {
    super.initState();
    _removeEscapeListener = onEscapePressed(component.onClose);
  }

  @override
  void dispose() {
    _removeEscapeListener?.call();
    super.dispose();
  }

  void _step(int delta) {
    final count = component.attachments.length;
    if (count == 0) return;
    setState(() => _index = (_index + delta) % count);
  }

  @override
  Component build(BuildContext context) {
    final translations = StreamChat.translationsOf(context);
    final attachments = component.attachments;
    if (attachments.isEmpty) return div([]);

    final current = attachments[_index.clamp(0, attachments.length - 1)];
    final url = previewUrlFor(current);
    final hasSiblings = attachments.length > 1;

    return div(
      [
        div(
          [
            if (hasSiblings)
              span(
                [Component.text('${_index + 1} / ${attachments.length}')],
                classes: 'sc-gallery__counter',
              ),
            if (url != null)
              button(
                [StreamIcons.download()],
                type: ButtonType.button,
                classes: 'sc-gallery__button',
                attributes: {'aria-label': translations.attachment},
                onClick: () => downloadUrl(
                  url,
                  current.title ?? 'image',
                ),
              ),
            button(
              [StreamIcons.close()],
              type: ButtonType.button,
              classes: 'sc-gallery__button',
              attributes: {'aria-label': translations.closeImageViewer},
              onClick: component.onClose,
            ),
          ],
          classes: 'sc-gallery__toolbar',
        ),
        if (hasSiblings)
          button(
            [StreamIcons.chevronLeft()],
            type: ButtonType.button,
            classes: 'sc-gallery__nav sc-gallery__nav--previous',
            attributes: {'aria-label': translations.previousImage},
            onClick: () => _step(-1),
          ),
        if (url != null)
          img(
            src: url,
            alt: current.title ?? translations.attachment,
            classes: 'sc-gallery__image',
          ),
        if (hasSiblings)
          button(
            [StreamIcons.chevronRight()],
            type: ButtonType.button,
            classes: 'sc-gallery__nav sc-gallery__nav--next',
            attributes: {'aria-label': translations.nextImage},
            onClick: () => _step(1),
          ),
      ],
      classes: 'sc-gallery',
      attributes: {
        'role': 'dialog',
        'aria-modal': 'true',
        'aria-label': translations.attachment,
      },
    );
  }
}
