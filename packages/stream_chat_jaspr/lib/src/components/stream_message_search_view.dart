import 'dart:async';

import 'package:jaspr/dom.dart' hide Filter;
import 'package:jaspr/jaspr.dart';
import 'package:stream_chat/stream_chat.dart';
import 'package:universal_web/web.dart' as web;

import '../core/stream_chat.dart';
import '../core/stream_message_search_controller.dart';
import '../i18n/stream_chat_translations.dart';
import '../util/formatting.dart';
import '../util/icons.dart';
import 'stream_avatar.dart';

/// A search field and its results.
///
/// Renders nothing but the field until a term is entered, so it can sit
/// permanently above a channel list without taking space away from it.
class StreamMessageSearchView extends StatefulComponent {
  /// Creates a search view.
  ///
  /// Provide either [controller] or [filter]. With [filter] the component
  /// creates and owns a controller, which is the common case.
  const StreamMessageSearchView({
    this.controller,
    this.filter,
    this.onResultTap,
    super.key,
  }) : assert(
          controller != null || filter != null,
          'Provide either a controller or a filter to scope the search.',
        );

  /// An externally owned controller.
  final StreamMessageSearchController? controller;

  /// The channel filter to scope the search to, when this component owns the
  /// controller.
  final Filter? filter;

  /// Called with the matching message and the channel it belongs to.
  final void Function(Message message, ChannelModel? channel)? onResultTap;

  @override
  State<StreamMessageSearchView> createState() =>
      _StreamMessageSearchViewState();
}

class _StreamMessageSearchViewState extends State<StreamMessageSearchView> {
  StreamMessageSearchController? _owned;

  StreamMessageSearchController get _controller =>
      component.controller ?? (_owned ??= _createController());

  StreamMessageSearchController _createController() {
    return StreamMessageSearchController(
      client: StreamChat.of(context).client,
      filter: component.filter!,
    );
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  void _onScroll(web.Event event) {
    final target = event.target as web.Element?;
    if (target == null) return;
    final remaining =
        target.scrollHeight - target.scrollTop - target.clientHeight;
    if (remaining <= 200) unawaited(_controller.loadMore());
  }

  @override
  Component build(BuildContext context) {
    final translations = StreamChat.translationsOf(context);
    final controller = _controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context) {
        return div(
          [
            _field(controller, translations),
            if (controller.isActive) _results(controller, translations),
          ],
          classes: 'sc-search',
        );
      },
    );
  }

  Component _field(
    StreamMessageSearchController controller,
    StreamChatTranslations translations,
  ) {
    return div(
      [
        StreamIcons.search(),
        input(
          type: InputType.search,
          value: controller.term,
          classes: 'sc-search__input',
          attributes: {
            'placeholder': translations.searchMessages,
            'aria-label': translations.searchMessages,
          },
          onInput: controller.search,
        ),
        if (controller.isActive)
          button(
            [StreamIcons.close()],
            type: ButtonType.button,
            classes: 'sc-icon-button',
            attributes: {'aria-label': translations.clearSearch},
            onClick: controller.clear,
          ),
      ],
      classes: 'sc-search__field',
    );
  }

  Component _results(
    StreamMessageSearchController controller,
    StreamChatTranslations translations,
  ) {
    if (controller.isLoading) {
      return div([], classes: 'sc-spinner');
    }
    if (controller.error != null) {
      return div(
        [Component.text('${controller.error}')],
        classes: 'sc-error',
      );
    }
    if (controller.results.isEmpty) {
      return div(
        [Component.text(translations.noSearchResults)],
        classes: 'sc-empty',
      );
    }

    return div(
      [
        for (final result in controller.results)
          _resultTile(result, translations),
        if (controller.isLoadingMore) div([], classes: 'sc-spinner'),
      ],
      classes: 'sc-search__results',
      events: {'scroll': _onScroll},
    );
  }

  Component _resultTile(
    GetMessageResponse result,
    StreamChatTranslations translations,
  ) {
    final message = result.message;
    final author = message.user;

    return button(
      [
        if (author != null) StreamAvatar.user(author, size: 32),
        div(
          [
            div(
              [
                span(
                  [Component.text(author?.name ?? '')],
                  classes: 'sc-channel-tile__name',
                ),
                span(
                  [
                    Component.text(
                      formatChannelTimestamp(
                        message.createdAt,
                        yesterday: translations.yesterday,
                      ),
                    ),
                  ],
                  classes: 'sc-channel-tile__time',
                ),
              ],
              classes: 'sc-channel-tile__row',
            ),
            span(
              [Component.text(message.text ?? translations.attachment)],
              classes: 'sc-channel-tile__preview',
            ),
            if (result.channel?.name case final name?)
              span([Component.text(name)], classes: 'sc-search__channel'),
          ],
          classes: 'sc-channel-tile__body',
        ),
      ],
      type: ButtonType.button,
      classes: 'sc-channel-tile',
      onClick: () => component.onResultTap?.call(message, result.channel),
    );
  }
}
