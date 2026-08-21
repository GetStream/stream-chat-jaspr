import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../util/dom.dart';

/// A small floating panel anchored to whatever renders it.
///
/// Dismissal is handled with a full-viewport transparent scrim behind the
/// panel rather than a document-level click listener. A listener would fire
/// for the very click that opened the popover, which then needs suppressing
/// with either a capture-phase check or a scheduled microtask. A scrim has no
/// such ordering problem: clicks outside land on the scrim, clicks inside land
/// on the panel, and nothing else in the page reacts while it is open.
///
/// The anchoring element must establish a positioning context, which the
/// stylesheet does through `.sc-popover-anchor`.
class StreamPopover extends StatefulComponent {
  /// Creates a popover.
  const StreamPopover({
    required this.children,
    required this.onDismiss,
    this.label,
    this.role = 'menu',
    this.placement = StreamPopoverPlacement.above,
    this.classes,
    super.key,
  });

  /// Contents of the panel.
  final List<Component> children;

  /// Called when the user clicks outside the panel or presses Escape.
  final void Function() onDismiss;

  /// Accessible name of the panel.
  final String? label;

  /// ARIA role of the panel. Use `dialog` for anything that is not a menu.
  final String role;

  /// Which side of the anchor the panel opens on.
  final StreamPopoverPlacement placement;

  /// Extra classes for the panel.
  final String? classes;

  @override
  State<StreamPopover> createState() => _StreamPopoverState();
}

/// Where a [StreamPopover] sits relative to its anchor.
enum StreamPopoverPlacement {
  /// Above the anchor, right aligned.
  above('sc-popover--above'),

  /// Below the anchor, right aligned.
  below('sc-popover--below');

  const StreamPopoverPlacement(this.className);

  /// The modifier class that positions the panel.
  final String className;
}

class _StreamPopoverState extends State<StreamPopover> {
  void Function()? _removeEscapeListener;

  @override
  void initState() {
    super.initState();
    _removeEscapeListener = onEscapePressed(component.onDismiss);
  }

  @override
  void dispose() {
    _removeEscapeListener?.call();
    super.dispose();
  }

  void _onScrimClick(web.Event event) {
    event.stopPropagation();
    component.onDismiss();
  }

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      div(
        [],
        classes: 'sc-popover__scrim',
        events: {'click': _onScrimClick, 'contextmenu': _onScrimClick},
      ),
      div(
        component.children,
        classes: [
          'sc-popover',
          component.placement.className,
          ?component.classes,
        ].join(' '),
        attributes: {
          'role': component.role,
          'aria-label': ?component.label,
        },
      ),
    ]);
  }
}
