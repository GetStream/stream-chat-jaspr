import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The line icons used across the package.
///
/// These are inline SVG rather than an icon font or sprite sheet so that a
/// component library stays a single Dart dependency with no asset pipeline to
/// wire up. Every glyph is drawn on a 24 unit grid and strokes in
/// `currentColor`, so sizing and colouring happen in CSS through `font-size`
/// and `color` on the parent.
abstract final class StreamIcons {
  static const _none = Color('none');

  /// Wraps [shape] in a correctly configured `<svg>` root.
  static Component _icon(String d, {String? label}) {
    return svg(
      [
        path(
          [],
          d: d,
          fill: _none,
          stroke: Color.currentColor,
          strokeWidth: '2',
          attributes: const {
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
          },
        ),
      ],
      viewBox: '0 0 24 24',
      classes: 'sc-icon',
      attributes: label == null
          ? const {'aria-hidden': 'true', 'focusable': 'false'}
          : {'role': 'img', 'aria-label': label},
    );
  }

  /// A filled paper plane, used for the send button.
  static Component send() {
    return svg(
      [path([], d: 'M2 21l21-9L2 3v7l15 2-15 2v7z', fill: Color.currentColor)],
      viewBox: '0 0 24 24',
      classes: 'sc-icon',
      attributes: const {'aria-hidden': 'true', 'focusable': 'false'},
    );
  }

  /// Paperclip, used to open the file picker.
  static Component paperclip() => _icon(
        'M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 '
        '5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48',
      );

  /// Smiling face, used to open the reaction picker.
  static Component smile() => _icon(
        'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20M8 14s1.5 2 4 2 4-2 4-2'
        'M9 9h.01M15 9h.01',
      );

  /// Horizontal ellipsis, used to open the message action menu.
  static Component more() => _icon(
        'M12 13a1 1 0 1 0 0-2 1 1 0 0 0 0 2'
        'M19 13a1 1 0 1 0 0-2 1 1 0 0 0 0 2'
        'M5 13a1 1 0 1 0 0-2 1 1 0 0 0 0 2',
      );

  /// Pencil, used for the edit action.
  static Component pencil() => _icon(
        'M17 3a2.83 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5z',
      );

  /// Waste bin, used for the delete action.
  static Component trash() => _icon(
        'M3 6h18M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2m3 0v14a1 1 0 0 1-1 '
        '1H6a1 1 0 0 1-1-1V6M10 11v6M14 11v6',
      );

  /// Left-turning arrow, used for the quote action.
  static Component reply() => _icon('M9 17l-6-6 6-6M3 11h11a6 6 0 0 1 6 6v3');

  /// Speech bubble, used for the thread action and reply counts.
  static Component thread() => _icon(
        'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z',
      );

  /// Push pin, used for the pin action.
  static Component pin() => _icon(
        'M12 17v5M9 10.76V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v5.76l2 3.24H7z',
      );

  /// Flag, used for the moderation action.
  static Component flag() =>
      _icon('M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1zM4 22V2');

  /// Overlapping sheets, used for the copy action.
  static Component copy() => _icon(
        'M9 9h10a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V10a1 1 0 0 1 '
        '1-1M5 15H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v1',
      );

  /// Cross, used to dismiss overlays and remove attachments.
  static Component close({String? label}) =>
      _icon('M18 6L6 18M6 6l12 12', label: label);

  /// Magnifier, used for search.
  static Component search() =>
      _icon('M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16M21 21l-4.35-4.35');

  /// Downward arrow into a tray, used for attachment downloads.
  static Component download() =>
      _icon('M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3');

  /// Filled triangle, used as the video play affordance.
  static Component play() {
    return svg(
      [path([], d: 'M8 5v14l11-7z', fill: Color.currentColor)],
      viewBox: '0 0 24 24',
      classes: 'sc-icon',
      attributes: const {'aria-hidden': 'true', 'focusable': 'false'},
    );
  }

  /// Single tick, used for a delivered message.
  static Component check() => _icon('M20 6L9 17l-5-5');

  /// Double tick, used for a read message.
  static Component checkAll() => _icon('M18 7l-8 8-4-4M22 7l-8 8-1-1');

  /// Clock, used for a message that is still in flight.
  static Component clock() => _icon('M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20M12 7v5l3 2');

  /// Downward chevron in a circle, used to jump to the newest message.
  static Component arrowDown() => _icon('M12 5v14M19 12l-7 7-7-7');

  /// Left chevron, used for back navigation and gallery paging.
  static Component chevronLeft() => _icon('M15 18l-6-6 6-6');

  /// Right chevron, used for gallery paging.
  static Component chevronRight() => _icon('M9 18l6-6-6-6');

  /// Warning triangle, used for failed uploads and sends.
  static Component alert() => _icon(
        'M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 '
        '3.86a2 2 0 0 0-3.42 0M12 9v4M12 17h.01',
      );

  /// Generic document, used for non-media attachments.
  static Component file() => _icon(
        'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8zM14 2v6h6',
      );
}
