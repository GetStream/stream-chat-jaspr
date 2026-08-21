import 'package:jaspr/dom.dart';

/// The stylesheet backing every component in this package.
///
/// Render it once, near the root of your app:
///
/// ```dart
/// Style(styles: streamChatStyles)
/// ```
///
/// [StreamChat] does this for you unless you pass `injectStyles: false`.
///
/// Every colour resolves through the CSS custom properties emitted by
/// [StreamChatTheme.cssVariables], so the same stylesheet serves every theme.
/// Rules are written with `raw` property maps rather than Jaspr's typed style
/// constructors: a design-system sheet of this size is easier to read and diff
/// as plain CSS, and it still goes through the same `StyleRule` renderer.
final List<StyleRule> streamChatStyles = [
  css('.sc-root', [
    css('&').styles(raw: {
      'font-family': 'var(--sc-font-family)',
      'color': 'var(--sc-text-primary)',
      'background': 'var(--sc-background)',
      'box-sizing': 'border-box',
      'height': '100%',
      '-webkit-font-smoothing': 'antialiased',
    }),
    css('*').styles(raw: {'box-sizing': 'border-box'}),
  ]),

  // ---------------------------------------------------------------- layout --
  css('.sc-shell').styles(raw: {
    'display': 'grid',
    'grid-template-columns': 'minmax(240px, 340px) 1fr',
    'height': '100%',
    'overflow': 'hidden',
  }),
  css.media(MediaQuery.screen(maxWidth: Unit.pixels(760)), [
    css('.sc-shell').styles(raw: {'grid-template-columns': '1fr'}),
    css('.sc-shell[data-pane="channel"] .sc-channel-list-pane')
        .styles(raw: {'display': 'none'}),
    css('.sc-shell[data-pane="list"] .sc-channel-pane')
        .styles(raw: {'display': 'none'}),
  ]),

  // ---------------------------------------------------------- channel list --
  css('.sc-channel-list-pane').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'min-height': '0',
    'border-right': '1px solid var(--sc-border)',
    'background': 'var(--sc-surface)',
  }),
  css('.sc-channel-list').styles(raw: {
    'flex': '1 1 auto',
    'min-height': '0',
    'overflow-y': 'auto',
    'overscroll-behavior': 'contain',
  }),
  css('.sc-channel-tile', [
    css('&').styles(raw: {
      'display': 'flex',
      'gap': '12px',
      'align-items': 'center',
      'width': '100%',
      'padding': '10px 14px',
      'border': 'none',
      'background': 'transparent',
      'color': 'inherit',
      'font': 'inherit',
      'text-align': 'left',
      'cursor': 'pointer',
      'transition': 'background 120ms ease',
    }),
    css('&:hover').styles(raw: {'background': 'var(--sc-surface-hover)'}),
    css('&[aria-selected="true"]').styles(raw: {
      'background': 'var(--sc-surface-hover)',
      'box-shadow': 'inset 3px 0 0 var(--sc-primary)',
    }),
  ]),
  css('.sc-channel-tile__body').styles(raw: {
    'flex': '1 1 auto',
    'min-width': '0',
  }),
  css('.sc-channel-tile__row').styles(raw: {
    'display': 'flex',
    'align-items': 'baseline',
    'justify-content': 'space-between',
    'gap': '8px',
  }),
  css('.sc-channel-tile__name').styles(raw: {
    'font-weight': '600',
    'font-size': '15px',
    'white-space': 'nowrap',
    'overflow': 'hidden',
    'text-overflow': 'ellipsis',
  }),
  css('.sc-channel-tile__preview').styles(raw: {
    'color': 'var(--sc-text-secondary)',
    'font-size': '13px',
    'white-space': 'nowrap',
    'overflow': 'hidden',
    'text-overflow': 'ellipsis',
    'margin-top': '2px',
  }),
  css('.sc-channel-tile__time').styles(raw: {
    'color': 'var(--sc-text-secondary)',
    'font-size': '12px',
    'flex': '0 0 auto',
  }),
  css('.sc-badge').styles(raw: {
    'display': 'inline-flex',
    'align-items': 'center',
    'justify-content': 'center',
    'min-width': '20px',
    'height': '20px',
    'padding': '0 6px',
    'border-radius': '10px',
    'background': 'var(--sc-primary)',
    'color': 'var(--sc-on-primary)',
    'font-size': '11px',
    'font-weight': '700',
    'flex': '0 0 auto',
  }),

  // --------------------------------------------------------------- avatars --
  css('.sc-avatar', [
    css('&').styles(raw: {
      'position': 'relative',
      'flex': '0 0 auto',
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
      'border-radius': '50%',
      'overflow': 'visible',
      'background': 'var(--sc-primary)',
      'color': 'var(--sc-on-primary)',
      'font-weight': '600',
      'user-select': 'none',
    }),
    css('& img').styles(raw: {
      'width': '100%',
      'height': '100%',
      'border-radius': '50%',
      'object-fit': 'cover',
      'display': 'block',
    }),
  ]),
  css('.sc-avatar__presence').styles(raw: {
    'position': 'absolute',
    'right': '0',
    'bottom': '0',
    'width': '30%',
    'height': '30%',
    'min-width': '8px',
    'min-height': '8px',
    'border-radius': '50%',
    'background': 'var(--sc-online)',
    'border': '2px solid var(--sc-surface)',
  }),

  // -------------------------------------------------------------- channel  --
  css('.sc-channel-pane').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'min-height': '0',
    'min-width': '0',
    'height': '100%',
    'background': 'var(--sc-background)',
  }),
  css('.sc-channel-header').styles(raw: {
    'display': 'flex',
    'align-items': 'center',
    'gap': '12px',
    'padding': '12px 16px',
    'border-bottom': '1px solid var(--sc-border)',
    'flex': '0 0 auto',
  }),
  css('.sc-channel-header__title').styles(raw: {
    'font-weight': '600',
    'font-size': '16px',
  }),
  css('.sc-channel-header__subtitle').styles(raw: {
    'color': 'var(--sc-text-secondary)',
    'font-size': '13px',
  }),

  // ---------------------------------------------------------- message list --
  // `column-reverse` keeps the viewport pinned to the newest message without
  // any imperative scrolling: new children are appended at the visual bottom
  // and the browser preserves the scroll anchor for us.
  css('.sc-message-list').styles(raw: {
    'flex': '1 1 auto',
    'min-height': '0',
    'display': 'flex',
    'flex-direction': 'column-reverse',
    'overflow-y': 'auto',
    'overscroll-behavior': 'contain',
    'padding': '16px',
    'gap': '2px',
  }),
  css('.sc-message-group').styles(raw: {
    'display': 'flex',
    'gap': '8px',
    'align-items': 'flex-end',
    'margin-top': '10px',
  }),
  css('.sc-message-group--own').styles(raw: {'flex-direction': 'row-reverse'}),
  css('.sc-message-group__spacer').styles(raw: {
    'flex': '0 0 auto',
    'width': '32px',
  }),
  css('.sc-message-group__stack').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'gap': '2px',
    'min-width': '0',
    'max-width': 'min(560px, 72%)',
  }),
  css('.sc-message-group--own .sc-message-group__stack')
      .styles(raw: {'align-items': 'flex-end'}),
  css('.sc-message-meta').styles(raw: {
    'display': 'flex',
    'gap': '6px',
    'align-items': 'baseline',
    'font-size': '12px',
    'color': 'var(--sc-text-secondary)',
    'margin-bottom': '2px',
    'padding': '0 4px',
  }),
  css('.sc-message-meta__author').styles(raw: {
    'font-weight': '600',
    'color': 'var(--sc-text-primary)',
  }),
  css('.sc-bubble', [
    css('&').styles(raw: {
      'padding': '8px 13px',
      'border-radius': 'var(--sc-radius)',
      'background': 'var(--sc-bubble-other)',
      'color': 'var(--sc-bubble-other-text)',
      'font-size': '15px',
      'line-height': '1.4',
      'overflow-wrap': 'anywhere',
      'white-space': 'pre-wrap',
      'width': 'fit-content',
      'max-width': '100%',
    }),
    css('&.sc-bubble--own').styles(raw: {
      'background': 'var(--sc-bubble-own)',
      'color': 'var(--sc-bubble-own-text)',
    }),
    css('&.sc-bubble--deleted').styles(raw: {
      'background': 'transparent',
      'border': '1px dashed var(--sc-border)',
      'color': 'var(--sc-text-secondary)',
      'font-style': 'italic',
    }),
    css('&.sc-bubble--failed').styles(raw: {
      'background': 'var(--sc-danger)',
      'color': '#fff',
    }),
    css('&.sc-bubble--pending').styles(raw: {'opacity': '0.6'}),
  ]),
  css('.sc-bubble__attachments').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'gap': '6px',
    'margin-top': '6px',
  }),
  css('.sc-attachment-image').styles(raw: {
    'max-width': '100%',
    'border-radius': '12px',
    'display': 'block',
  }),
  css('.sc-attachment-file', [
    css('&').styles(raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'padding': '8px 10px',
      'border-radius': '10px',
      'background': 'var(--sc-surface)',
      'color': 'var(--sc-text-primary)',
      'text-decoration': 'none',
      'font-size': '14px',
    }),
    css('&:hover').styles(raw: {'background': 'var(--sc-surface-hover)'}),
  ]),
  css('.sc-reactions').styles(raw: {
    'display': 'flex',
    'flex-wrap': 'wrap',
    'gap': '4px',
    'margin-top': '4px',
    'padding': '0 4px',
  }),
  css('.sc-reaction', [
    css('&').styles(raw: {
      'display': 'inline-flex',
      'align-items': 'center',
      'gap': '4px',
      'padding': '2px 8px',
      'border-radius': '12px',
      'border': '1px solid var(--sc-border)',
      'background': 'var(--sc-surface)',
      'color': 'var(--sc-text-primary)',
      'font-size': '12px',
      'cursor': 'pointer',
      'font-family': 'inherit',
    }),
    css('&:hover').styles(raw: {'background': 'var(--sc-surface-hover)'}),
    css('&.sc-reaction--own').styles(raw: {
      'border-color': 'var(--sc-primary)',
      'color': 'var(--sc-primary)',
    }),
  ]),
  css('.sc-date-divider').styles(raw: {
    'align-self': 'center',
    'margin': '16px 0 6px',
    'padding': '3px 12px',
    'border-radius': '12px',
    'background': 'var(--sc-surface)',
    'color': 'var(--sc-text-secondary)',
    'font-size': '12px',
    'font-weight': '600',
  }),

  // --------------------------------------------------------------- composer --
  css('.sc-composer').styles(raw: {
    'display': 'flex',
    'align-items': 'center',
    'gap': '8px',
    'padding': '12px 16px',
    'border-top': '1px solid var(--sc-border)',
    'flex': '0 0 auto',
  }),
  css('.sc-composer__input', [
    css('&').styles(raw: {
      'flex': '1 1 auto',
      'min-width': '0',
      'padding': '10px 14px',
      'border-radius': '20px',
      'border': '1px solid var(--sc-border)',
      'background': 'var(--sc-surface)',
      'color': 'var(--sc-text-primary)',
      'font': 'inherit',
      'font-size': '15px',
      'outline': 'none',
    }),
    css('&:focus').styles(raw: {
      'border-color': 'var(--sc-primary)',
      'background': 'var(--sc-background)',
    }),
    css('&::placeholder').styles(raw: {'color': 'var(--sc-text-secondary)'}),
    css('&:disabled').styles(raw: {'opacity': '0.6', 'cursor': 'not-allowed'}),
  ]),
  css('.sc-composer__send', [
    css('&').styles(raw: {
      'flex': '0 0 auto',
      'width': '40px',
      'height': '40px',
      'border-radius': '50%',
      'border': 'none',
      'background': 'var(--sc-primary)',
      'color': 'var(--sc-on-primary)',
      'cursor': 'pointer',
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
      'transition': 'background 120ms ease, opacity 120ms ease',
    }),
    css('&:hover:not(:disabled)')
        .styles(raw: {'background': 'var(--sc-primary-hover)'}),
    css('&:disabled').styles(raw: {'opacity': '0.4', 'cursor': 'default'}),
    css('& svg').styles(raw: {'width': '20px', 'height': '20px'}),
  ]),

  // ------------------------------------------------------------- indicators --
  css('.sc-typing').styles(raw: {
    'height': '20px',
    'padding': '0 18px 4px',
    'font-size': '12px',
    'color': 'var(--sc-text-secondary)',
    'flex': '0 0 auto',
  }),
  css('.sc-connection-banner').styles(raw: {
    'padding': '6px 16px',
    'font-size': '13px',
    'text-align': 'center',
    'background': 'var(--sc-danger)',
    'color': '#fff',
    'flex': '0 0 auto',
  }),
  css('.sc-connection-banner--connecting')
      .styles(raw: {'background': 'var(--sc-text-secondary)'}),
  css('.sc-empty').styles(raw: {
    'display': 'flex',
    'flex': '1 1 auto',
    'align-items': 'center',
    'justify-content': 'center',
    'padding': '32px',
    'text-align': 'center',
    'color': 'var(--sc-text-secondary)',
    'font-size': '14px',
  }),
  css('.sc-error').styles(raw: {
    'padding': '16px',
    'color': 'var(--sc-danger)',
    'font-size': '14px',
  }),
  css('.sc-spinner', [
    css('&').styles(raw: {
      'width': '22px',
      'height': '22px',
      'margin': '18px auto',
      'border': '2px solid var(--sc-border)',
      'border-top-color': 'var(--sc-primary)',
      'border-radius': '50%',
      'animation': 'sc-spin 700ms linear infinite',
    }),
  ]),
  StyleRule.keyframes(name: 'sc-spin', styles: {
    'from': Styles(raw: {'transform': 'rotate(0deg)'}),
    'to': Styles(raw: {'transform': 'rotate(360deg)'}),
  }),
];
