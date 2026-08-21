import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Emoji shown for each of Stream's default reaction types.
///
/// Unknown types fall through to the raw type string in the UI, so custom
/// reactions configured on a Stream application still render something rather
/// than disappearing.
const Map<String, String> defaultReactionEmoji = {
  'like': '\u{1F44D}',
  'love': '\u{2764}\u{FE0F}',
  'haha': '\u{1F602}',
  'wow': '\u{1F62E}',
  'sad': '\u{1F622}',
  'angry': '\u{1F621}',
};

/// The row of reactions offered when adding one to a message.
///
/// Deliberately limited to the types the Stream dashboard enables by default.
/// A full emoji keyboard would mean shipping an emoji index, which is a large
/// dependency for something most applications restrict anyway.
class StreamReactionPicker extends StatelessComponent {
  /// Creates a reaction picker.
  const StreamReactionPicker({
    required this.onSelected,
    this.ownReactions = const {},
    this.types = defaultReactionEmoji,
    super.key,
  });

  /// Called with the chosen reaction type.
  final void Function(String type) onSelected;

  /// Types the current user has already reacted with, which render as active
  /// and remove the reaction when chosen again.
  final Set<String> ownReactions;

  /// Reaction types to offer, mapped to the emoji that represents them.
  final Map<String, String> types;

  @override
  Component build(BuildContext context) {
    return div(
      [
        for (final MapEntry(key: type, value: emoji) in types.entries)
          button(
            [Component.text(emoji)],
            type: ButtonType.button,
            classes: ownReactions.contains(type)
                ? 'sc-reaction-picker__option sc-reaction-picker__option--own'
                : 'sc-reaction-picker__option',
            attributes: {
              'aria-label': type,
              'aria-pressed': '${ownReactions.contains(type)}',
              'title': type,
            },
            onClick: () => onSelected(type),
          ),
      ],
      classes: 'sc-reaction-picker',
    );
  }
}
