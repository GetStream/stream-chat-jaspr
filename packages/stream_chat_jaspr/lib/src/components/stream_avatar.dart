import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';

import '../util/formatting.dart';

/// A circular avatar that falls back to coloured initials.
///
/// The fallback colour is derived from [seed], so the same user always gets
/// the same colour across sessions and devices without storing anything.
///
/// The initials are always rendered, with any photo laid over the top. That
/// way a slow or broken image shows initials rather than an empty disc.
class StreamAvatar extends StatefulComponent {
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
  State<StreamAvatar> createState() => _StreamAvatarState();
}

class _StreamAvatarState extends State<StreamAvatar> {
  bool _imageFailed = false;

  @override
  void didUpdateComponent(StreamAvatar oldComponent) {
    super.didUpdateComponent(oldComponent);
    // A new URL deserves a fresh attempt, otherwise recycling this element for
    // another user would inherit the previous one's failure.
    if (oldComponent.imageUrl != component.imageUrl) _imageFailed = false;
  }

  @override
  Component build(BuildContext context) {
    final url = component.imageUrl;
    final name = component.name;
    final size = component.size;
    final hue = hueFor(component.seed ?? name ?? '');
    final showImage = url != null && url.isNotEmpty && !_imageFailed;

    return div(
      [
        Component.text(initialsFor(name)),
        if (showImage)
          img(
            src: url,
            alt: name ?? '',
            events: {
              'error': (_) {
                if (_imageFailed) return;
                setState(() => _imageFailed = true);
              },
            },
          ),
        if (component.showPresence) div([], classes: 'sc-avatar__presence'),
      ],
      classes: 'sc-avatar',
      styles: Styles(raw: {
        'width': '${size}px',
        'height': '${size}px',
        'font-size': '${(size * 0.38).toStringAsFixed(1)}px',
        'background': 'hsl($hue 52% 46%)',
      }),
    );
  }
}
