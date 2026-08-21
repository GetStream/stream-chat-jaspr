import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../util/formatting.dart';

/// A circular avatar that falls back to coloured initials.
///
/// The fallback colour is derived from [seed], so the same user always gets
/// the same colour across sessions and devices without storing anything.
class StreamAvatar extends StatelessComponent {
  /// Creates an avatar.
  const StreamAvatar({
    this.name,
    this.imageUrl,
    this.seed,
    this.size = 40,
    this.showPresence = false,
    super.key,
  });

  /// Creates an avatar for [user], including their presence dot.
  factory StreamAvatar.user(
    User user, {
    double size = 40,
    bool showPresence = false,
  }) {
    return StreamAvatar(
      name: user.name,
      imageUrl: user.image,
      seed: user.id,
      size: size,
      showPresence: showPresence && user.online,
    );
  }

  /// Creates an avatar for [channel].
  ///
  /// Named channels use their own image. Direct conversations fall back to the
  /// other participant, which is what makes a 1:1 chat look like the person
  /// you are talking to rather than an anonymous group.
  factory StreamAvatar.channel(
    Channel channel, {
    required String? currentUserId,
    double size = 40,
    bool showPresence = true,
  }) {
    final image = channel.image;
    if (image != null) {
      return StreamAvatar(
        name: channel.name,
        imageUrl: image,
        seed: channel.cid ?? channel.id ?? '',
        size: size,
      );
    }

    final others = channel.state?.members
            .where((it) => it.userId != currentUserId)
            .toList() ??
        const <Member>[];

    final soleOther = others.length == 1 ? others.first.user : null;
    if (soleOther != null) {
      return StreamAvatar.user(
        soleOther,
        size: size,
        showPresence: showPresence,
      );
    }

    return StreamAvatar(
      name: channel.name ?? channel.id,
      seed: channel.cid ?? channel.id ?? '',
      size: size,
    );
  }

  /// Display name, used for the initials fallback and the image alt text.
  final String? name;

  /// Remote image to show instead of initials.
  final String? imageUrl;

  /// Value the fallback colour is derived from. Defaults to [name].
  final String? seed;

  /// Diameter in CSS pixels.
  final double size;

  /// Whether to render the online presence dot.
  final bool showPresence;

  @override
  Component build(BuildContext context) {
    final url = imageUrl;
    final hue = hueFor(seed ?? name ?? '');

    return div(
      [
        if (url != null && url.isNotEmpty)
          img(src: url, alt: name ?? '')
        else
          Component.text(initialsFor(name)),
        if (showPresence) div([], classes: 'sc-avatar__presence'),
      ],
      classes: 'sc-avatar',
      styles: Styles(raw: {
        'width': '${size}px',
        'height': '${size}px',
        'font-size': '${(size * 0.38).toStringAsFixed(1)}px',
        if (url == null || url.isEmpty) 'background': 'hsl($hue 52% 46%)',
      }),
    );
  }
}
