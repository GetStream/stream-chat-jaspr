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

  // ----------------------------------------------------------- primitives --
  css('.sc-icon').styles(raw: {
    'width': '1em',
    'height': '1em',
    'flex': '0 0 auto',
    'display': 'block',
  }),
  // Kept in the accessibility tree and focusable, unlike `display: none`.
  css('.sc-visually-hidden').styles(raw: {
    'position': 'absolute',
    'width': '1px',
    'height': '1px',
    'padding': '0',
    'margin': '-1px',
    'overflow': 'hidden',
    'clip-path': 'inset(50%)',
    'white-space': 'nowrap',
    'border': '0',
  }),
  css('.sc-icon-button', [
    css('&').styles(raw: {
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
      'width': '32px',
      'height': '32px',
      'flex': '0 0 auto',
      'padding': '0',
      'border': 'none',
      'border-radius': '8px',
      'background': 'transparent',
      'color': 'var(--sc-text-secondary)',
      'font-size': '18px',
      'cursor': 'pointer',
      'transition': 'background 120ms ease, color 120ms ease',
    }),
    css('&:hover').styles(raw: {
      'background': 'var(--sc-surface-hover)',
      'color': 'var(--sc-text-primary)',
    }),
  ]),
  css('.sc-button', [
    css('&').styles(raw: {
      'padding': '7px 14px',
      'border-radius': '8px',
      'border': '1px solid transparent',
      'font': 'inherit',
      'font-size': '14px',
      'font-weight': '600',
      'cursor': 'pointer',
    }),
    css('&.sc-button--ghost').styles(raw: {
      'background': 'transparent',
      'border-color': 'var(--sc-border)',
      'color': 'var(--sc-text-primary)',
    }),
    css('&.sc-button--ghost:hover')
        .styles(raw: {'background': 'var(--sc-surface-hover)'}),
    css('&.sc-button--danger').styles(raw: {
      'background': 'var(--sc-danger)',
      'color': '#fff',
    }),
  ]),
  css('.sc-focus-ring:focus-visible').styles(raw: {
    'outline': '2px solid var(--sc-primary)',
    'outline-offset': '2px',
  }),

  // -------------------------------------------------------------- popover --
  css('.sc-popover-anchor').styles(raw: {'position': 'relative'}),
  // Covers the viewport so any click outside the panel closes it, without a
  // document listener that would also catch the click that opened it.
  css('.sc-popover__scrim').styles(raw: {
    'position': 'fixed',
    'inset': '0',
    'z-index': '40',
  }),
  css('.sc-popover', [
    css('&').styles(raw: {
      'position': 'absolute',
      'right': '0',
      'z-index': '41',
      'min-width': '200px',
      'padding': '6px',
      'border-radius': '12px',
      'border': '1px solid var(--sc-border)',
      'background': 'var(--sc-background)',
      'box-shadow': '0 12px 32px rgba(0, 0, 0, 0.18)',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '2px',
    }),
    css('&.sc-popover--above').styles(raw: {'bottom': 'calc(100% + 6px)'}),
    css('&.sc-popover--below').styles(raw: {'top': 'calc(100% + 6px)'}),
    css('&.sc-popover--reactions').styles(raw: {
      'min-width': '0',
      'flex-direction': 'row',
      'border-radius': '22px',
      'padding': '4px',
    }),
    css('&.sc-popover--confirm').styles(raw: {
      'width': '260px',
      'padding': '14px',
      'gap': '10px',
      'font-size': '14px',
    }),
  ]),
  css('.sc-popover p').styles(raw: {'margin': '0', 'line-height': '1.45'}),
  css('.sc-popover__actions').styles(raw: {
    'display': 'flex',
    'justify-content': 'flex-end',
    'gap': '8px',
  }),
  css('.sc-menu-item', [
    css('&').styles(raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': '10px',
      'width': '100%',
      'padding': '8px 10px',
      'border': 'none',
      'border-radius': '8px',
      'background': 'transparent',
      'color': 'var(--sc-text-primary)',
      'font': 'inherit',
      'font-size': '14px',
      'text-align': 'left',
      'cursor': 'pointer',
    }),
    css('&:hover').styles(raw: {'background': 'var(--sc-surface-hover)'}),
    css('& .sc-icon').styles(raw: {'font-size': '17px', 'opacity': '0.75'}),
    css('&.sc-menu-item--danger').styles(raw: {'color': 'var(--sc-danger)'}),
  ]),

  // ---------------------------------------------------------------- layout --
  css('.sc-shell').styles(raw: {
    'display': 'grid',
    'grid-template-columns': 'minmax(240px, 340px) 1fr',
    'height': '100%',
    'overflow': 'hidden',
  }),
  // The conversation and its open thread sit side by side inside the channel
  // pane rather than as columns of the shell grid. Keeping the split below
  // StreamChannel is what lets the thread state live on the channel scope,
  // where the action menu on a message can reach it.
  css('.sc-conversation-split').styles(raw: {
    'display': 'flex',
    'flex': '1 1 auto',
    'min-height': '0',
    'min-width': '0',
  }),
  css('.sc-conversation').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'flex': '1 1 auto',
    'min-width': '0',
    'min-height': '0',
  }),
  css('.sc-conversation-split .sc-thread')
      .styles(raw: {'flex': '0 0 auto', 'width': '360px'}),
  css.media(MediaQuery.screen(maxWidth: Unit.pixels(1100)), [
    // Two full columns stop fitting well before the mobile breakpoint, so the
    // thread replaces the channel list rather than squeezing everything.
    //
    // The template has to collapse along with it. Hiding a grid child does not
    // remove its column, so leaving two columns here would drop the channel
    // pane into the narrow first one and leave the wide one empty, squeezing
    // the conversation to nothing behind the thread.
    css('.sc-shell:has(.sc-conversation-split[data-thread="open"])')
        .styles(raw: {'grid-template-columns': '1fr'}),
    css('.sc-shell:has(.sc-conversation-split[data-thread="open"]) '
            '.sc-channel-list-pane')
        .styles(raw: {'display': 'none'}),
  ]),
  css.media(MediaQuery.screen(maxWidth: Unit.pixels(760)), [
    css('.sc-shell').styles(raw: {'grid-template-columns': '1fr'}),
    css('.sc-shell[data-pane="channel"] .sc-channel-list-pane')
        .styles(raw: {'display': 'none'}),
    css('.sc-shell[data-pane="list"] .sc-channel-pane')
        .styles(raw: {'display': 'none'}),
    // One column is all there is room for, so the thread takes the whole pane.
    css('.sc-conversation-split[data-thread="open"] .sc-conversation')
        .styles(raw: {'display': 'none'}),
    css('.sc-conversation-split .sc-thread')
        .styles(raw: {'width': 'auto', 'flex': '1 1 auto'}),
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

  // --------------------------------------------------------------- search --
  css('.sc-search').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'min-height': '0',
    // Never shrink. The channel list beside it is as tall as its content, so
    // any shrink factor here hands most of the pane to the list and squeezes
    // the field down until it spills out of its own box and the list, being
    // the later sibling, paints over it. The results pane below caps itself.
    'flex': '0 0 auto',
  }),
  css('.sc-search__field', [
    css('&').styles(raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'margin': '8px 12px',
      'padding': '6px 10px',
      'border-radius': '10px',
      'background': 'var(--sc-background)',
      'border': '1px solid var(--sc-border)',
      'color': 'var(--sc-text-secondary)',
      'flex': '0 0 auto',
      'font-size': '16px',
    }),
    css('&:focus-within').styles(raw: {'border-color': 'var(--sc-primary)'}),
  ]),
  css('.sc-search__input', [
    css('&').styles(raw: {
      'flex': '1 1 auto',
      'min-width': '0',
      'border': 'none',
      'background': 'transparent',
      'color': 'var(--sc-text-primary)',
      'font': 'inherit',
      'font-size': '14px',
      'outline': 'none',
    }),
    css('&::placeholder').styles(raw: {'color': 'var(--sc-text-secondary)'}),
  ]),
  css('.sc-search__results').styles(raw: {
    'overflow-y': 'auto',
    'min-height': '0',
    'max-height': '50vh',
    'border-top': '1px solid var(--sc-border)',
  }),
  css('.sc-search__channel').styles(raw: {
    'display': 'block',
    'margin-top': '2px',
    'font-size': '12px',
    'color': 'var(--sc-text-secondary)',
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
    // Laid over the initials rather than replacing them, so a photo that is
    // still downloading or that never arrives leaves something readable
    // behind instead of a blank disc.
    css('& img').styles(raw: {
      'position': 'absolute',
      'inset': '0',
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
  css('.sc-message-list-wrap').styles(raw: {
    'position': 'relative',
    'flex': '1 1 auto',
    'min-height': '0',
    'display': 'flex',
    'flex-direction': 'column',
  }),
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
  css('.sc-jump-to-latest', [
    css('&').styles(raw: {
      'position': 'absolute',
      'right': '18px',
      'bottom': '14px',
      'width': '36px',
      'height': '36px',
      'border-radius': '50%',
      'border': '1px solid var(--sc-border)',
      'background': 'var(--sc-background)',
      'color': 'var(--sc-text-primary)',
      'font-size': '18px',
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
      'cursor': 'pointer',
      'box-shadow': '0 6px 18px rgba(0, 0, 0, 0.16)',
    }),
    css('&:hover').styles(raw: {'background': 'var(--sc-surface-hover)'}),
  ]),
  css('.sc-message-group', [
    css('&').styles(raw: {
      'display': 'flex',
      'gap': '8px',
      'align-items': 'flex-end',
      'margin-top': '10px',
    }),
    css('&.sc-message-group--own').styles(raw: {'flex-direction': 'row-reverse'}),
    css('&.sc-message-group--highlighted').styles(raw: {
      'background': 'color-mix(in srgb, var(--sc-primary) 12%, transparent)',
      'border-radius': '12px',
    }),
  ]),
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
  css('.sc-message-group__row').styles(raw: {
    'display': 'flex',
    'align-items': 'center',
    'gap': '6px',
    'min-width': '0',
    'max-width': '100%',
  }),
  css('.sc-message-group--own .sc-message-group__row')
      .styles(raw: {'flex-direction': 'row-reverse'}),
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
  css('.sc-message-meta__edited').styles(raw: {'font-style': 'italic'}),
  css('.sc-message-pinned').styles(raw: {
    'display': 'flex',
    'align-items': 'center',
    'gap': '5px',
    'font-size': '11px',
    'font-weight': '600',
    'color': 'var(--sc-text-secondary)',
    'padding': '0 4px 2px',
  }),

  // ------------------------------------------------------------- bubbles  --
  css('.sc-bubble', [
    css('&').styles(raw: {
      'padding': '8px 13px',
      'border-radius': 'var(--sc-radius)',
      'background': 'var(--sc-bubble-other)',
      'color': 'var(--sc-bubble-other-text)',
      'font-size': '15px',
      'line-height': '1.4',
      'overflow-wrap': 'anywhere',
      'width': 'fit-content',
      'max-width': '100%',
      'min-width': '0',
    }),
    css('&.sc-bubble--own').styles(raw: {
      'background': 'var(--sc-bubble-own)',
      'color': 'var(--sc-bubble-own-text)',
    }),
    css('&.sc-bubble--bare').styles(raw: {
      'padding': '0',
      'background': 'transparent',
    }),
    css('&.sc-bubble--bare .sc-attachments').styles(raw: {'margin-top': '0'}),
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
  css('.sc-bubble__text').styles(raw: {'white-space': 'pre-wrap'}),
  css('.sc-link', [
    css('&').styles(raw: {
      'color': 'inherit',
      'text-decoration': 'underline',
      'text-underline-offset': '2px',
    }),
    css('&:hover').styles(raw: {'text-decoration-thickness': '2px'}),
  ]),
  css('.sc-mention').styles(raw: {
    'font-weight': '600',
    'color': 'var(--sc-primary)',
  }),
  css('.sc-bubble--own .sc-mention').styles(raw: {'color': 'inherit'}),
  css('.sc-code').styles(raw: {
    'font-family': 'ui-monospace, SFMono-Regular, Menlo, monospace',
    'font-size': '0.9em',
    'padding': '1px 5px',
    'border-radius': '5px',
    'background': 'rgba(127, 127, 127, 0.18)',
  }),
  css('.sc-quoted', [
    css('&').styles(raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '1px',
      'width': '100%',
      // Without a floor the block shrinks to its longest word, and a one word
      // reply to a one word message reads as a stack of loose text.
      'min-width': '140px',
      'margin-bottom': '6px',
      'padding': '6px 10px',
      'border': 'none',
      'border-left': '3px solid currentColor',
      'border-radius': '6px',
      'background': 'rgba(127, 127, 127, 0.16)',
      'color': 'inherit',
      'font': 'inherit',
      'font-size': '13px',
      'text-align': 'left',
      'cursor': 'pointer',
      'opacity': '0.85',
    }),
    css('&:hover').styles(raw: {'opacity': '1'}),
  ]),
  css('.sc-quoted__author').styles(raw: {'font-weight': '600'}),
  css('.sc-quoted__text').styles(raw: {
    'display': '-webkit-box',
    '-webkit-line-clamp': '2',
    '-webkit-box-orient': 'vertical',
    'overflow': 'hidden',
  }),
  css('.sc-thread-footer', [
    css('&').styles(raw: {
      'display': 'inline-flex',
      'align-items': 'center',
      'gap': '6px',
      'margin-top': '3px',
      'padding': '2px 6px',
      'border': 'none',
      'border-radius': '8px',
      'background': 'transparent',
      'color': 'var(--sc-primary)',
      'font': 'inherit',
      'font-size': '12px',
      'font-weight': '600',
      'cursor': 'pointer',
    }),
    css('&:hover').styles(raw: {'background': 'var(--sc-surface-hover)'}),
  ]),
  css('.sc-delivery', [
    css('&').styles(raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': '4px',
      'margin-top': '2px',
      'padding': '0 4px',
      'font-size': '11px',
      'color': 'var(--sc-text-secondary)',
    }),
    css('&.sc-delivery--failed').styles(raw: {'color': 'var(--sc-danger)'}),
  ]),

  // ------------------------------------------------------------ reactions --
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
  css('.sc-reaction-picker').styles(raw: {'display': 'flex', 'gap': '2px'}),
  css('.sc-reaction-picker__option', [
    css('&').styles(raw: {
      'width': '34px',
      'height': '34px',
      'border': 'none',
      'border-radius': '50%',
      'background': 'transparent',
      'font-size': '19px',
      'line-height': '1',
      'cursor': 'pointer',
      'transition': 'transform 120ms ease, background 120ms ease',
    }),
    css('&:hover').styles(raw: {
      'background': 'var(--sc-surface-hover)',
      'transform': 'scale(1.15)',
    }),
    css('&.sc-reaction-picker__option--own')
        .styles(raw: {'background': 'var(--sc-surface-hover)'}),
  ]),

  // ------------------------------------------------------- message actions --
  css('.sc-message-actions').styles(raw: {'flex': '0 0 auto'}),
  css('.sc-message-actions__bar', [
    css('&').styles(raw: {
      'display': 'flex',
      'gap': '2px',
      'padding': '2px',
      'border-radius': '10px',
      'border': '1px solid var(--sc-border)',
      'background': 'var(--sc-background)',
      'box-shadow': '0 2px 8px rgba(0, 0, 0, 0.10)',
      // Faded out until the message is hovered or something inside it has
      // focus, so a quiet conversation stays quiet. Opacity rather than
      // `visibility` or `display`: the first keeps the row from reflowing on
      // hover, and both of the others would take the buttons out of the tab
      // order, which would make the actions unreachable by keyboard and stop
      // `:focus-within` from ever matching.
      'opacity': '0',
      'transition': 'opacity 120ms ease',
    }),
  ]),
  css('.sc-message-group:hover .sc-message-actions__bar')
      .styles(raw: {'opacity': '1'}),
  css('.sc-message-group:focus-within .sc-message-actions__bar')
      .styles(raw: {'opacity': '1'}),
  css('.sc-message-actions__button', [
    css('&').styles(raw: {
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
      'width': '26px',
      'height': '26px',
      'padding': '0',
      'border': 'none',
      'border-radius': '7px',
      'background': 'transparent',
      'color': 'var(--sc-text-secondary)',
      'font-size': '16px',
      'cursor': 'pointer',
    }),
    css('&:hover').styles(raw: {
      'background': 'var(--sc-surface-hover)',
      'color': 'var(--sc-text-primary)',
    }),
  ]),
  css('.sc-message-actions__notice').styles(raw: {
    'position': 'absolute',
    'right': '0',
    'top': 'calc(100% + 4px)',
    'z-index': '30',
    'padding': '4px 8px',
    'border-radius': '7px',
    'background': 'var(--sc-surface-hover)',
    'color': 'var(--sc-text-secondary)',
    'font-size': '12px',
    'white-space': 'nowrap',
  }),

  // ---------------------------------------------------------- attachments --
  css('.sc-attachments').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'gap': '6px',
    'margin-top': '6px',
  }),
  css('.sc-attachment-grid', [
    css('&').styles(raw: {
      'display': 'grid',
      'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
      'gap': '4px',
      'max-width': '320px',
    }),
    css('&.sc-attachment-grid--single')
        .styles(raw: {'grid-template-columns': 'minmax(0, 1fr)'}),
  ]),
  css('.sc-attachment-grid__cell', [
    css('&').styles(raw: {
      'position': 'relative',
      'display': 'block',
      'padding': '0',
      'border': 'none',
      'border-radius': '12px',
      'overflow': 'hidden',
      'background': 'var(--sc-surface)',
      'cursor': 'pointer',
      'line-height': '0',
      // A portrait photo would otherwise run the height of the conversation.
      'max-height': '320px',
    }),
    css('&[disabled]').styles(raw: {'cursor': 'default'}),
  ]),
  // The cell reserves the shape, so the image fills it rather than defining it.
  css('.sc-attachment-grid__image').styles(raw: {
    'width': '100%',
    'height': '100%',
    'object-fit': 'cover',
    'display': 'block',
  }),
  css('.sc-attachment-grid__placeholder').styles(raw: {
    'display': 'flex',
    'align-items': 'center',
    'justify-content': 'center',
    'width': '100%',
    'height': '100%',
    'font-size': '28px',
    'color': 'var(--sc-text-secondary)',
  }),
  css('.sc-attachment-image').styles(raw: {
    'max-width': '100%',
    'border-radius': '12px',
    'display': 'block',
  }),
  css('.sc-attachment-video').styles(raw: {
    'max-width': '320px',
    'width': '100%',
    'border-radius': '12px',
    'display': 'block',
    'background': '#000',
  }),
  css('.sc-attachment-audio').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'gap': '4px',
    'min-width': '240px',
  }),
  css('.sc-attachment-audio__title').styles(raw: {
    'font-size': '13px',
    'font-weight': '600',
  }),
  css('.sc-attachment-audio__player').styles(raw: {'width': '100%'}),
  css('.sc-attachment-file', [
    css('&').styles(raw: {
      'position': 'relative',
      'display': 'flex',
      'align-items': 'center',
      'gap': '10px',
      'padding': '8px 10px',
      'border-radius': '10px',
      'background': 'var(--sc-surface)',
      'color': 'var(--sc-text-primary)',
      'text-decoration': 'none',
      'font-size': '14px',
      'min-width': '200px',
    }),
    css('&:hover').styles(raw: {'background': 'var(--sc-surface-hover)'}),
    css('& .sc-icon').styles(raw: {'font-size': '22px', 'opacity': '0.7'}),
  ]),
  css('.sc-attachment-file__body').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'min-width': '0',
  }),
  css('.sc-attachment-file__name').styles(raw: {
    'white-space': 'nowrap',
    'overflow': 'hidden',
    'text-overflow': 'ellipsis',
  }),
  css('.sc-attachment-file__meta').styles(raw: {
    'font-size': '12px',
    'color': 'var(--sc-text-secondary)',
  }),
  css('.sc-attachment-overlay', [
    css('&').styles(raw: {
      'position': 'absolute',
      'inset': '0',
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'justify-content': 'center',
      'gap': '6px',
      'padding': '10px',
      'background': 'rgba(0, 0, 0, 0.42)',
      'color': '#fff',
      'font-size': '12px',
      'border-radius': 'inherit',
    }),
    css('&.sc-attachment-overlay--failed')
        .styles(raw: {'background': 'rgba(0, 0, 0, 0.62)'}),
    css('& .sc-icon').styles(raw: {'font-size': '20px'}),
  ]),
  css('.sc-progress', [
    css('&').styles(raw: {
      'width': '70%',
      'height': '4px',
      'border-radius': '2px',
      'background': 'rgba(255, 255, 255, 0.32)',
      'overflow': 'hidden',
    }),
  ]),
  css('.sc-progress__fill').styles(raw: {
    'height': '100%',
    'background': '#fff',
    'border-radius': 'inherit',
    'transition': 'width 160ms linear',
  }),
  // Without a total to divide by there is no meaningful width, so the bar
  // sweeps instead of filling.
  css('.sc-progress--indeterminate .sc-progress__fill').styles(raw: {
    'width': '40%',
    'animation': 'sc-sweep 1100ms ease-in-out infinite',
  }),
  StyleRule.keyframes(name: 'sc-sweep', styles: {
    'from': Styles(raw: {'transform': 'translateX(-100%)'}),
    'to': Styles(raw: {'transform': 'translateX(250%)'}),
  }),
  css('.sc-link-preview__anchor')
      .styles(raw: {'text-decoration': 'none', 'color': 'inherit'}),
  css('.sc-link-preview', [
    css('&').styles(raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'max-width': '320px',
      'border': '1px solid var(--sc-border)',
      'border-radius': '12px',
      'overflow': 'hidden',
      'background': 'var(--sc-surface)',
    }),
    css('&:hover').styles(raw: {'background': 'var(--sc-surface-hover)'}),
  ]),
  css('.sc-link-preview__image').styles(raw: {
    'width': '100%',
    'max-height': '160px',
    'object-fit': 'cover',
    'display': 'block',
  }),
  css('.sc-link-preview__body').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'gap': '2px',
    'padding': '8px 10px',
    'font-size': '13px',
  }),
  css('.sc-link-preview__author').styles(raw: {
    'font-size': '11px',
    'text-transform': 'uppercase',
    'letter-spacing': '0.04em',
    'color': 'var(--sc-text-secondary)',
  }),
  css('.sc-link-preview__title').styles(raw: {'font-weight': '600'}),
  css('.sc-link-preview__text').styles(raw: {
    'color': 'var(--sc-text-secondary)',
    'display': '-webkit-box',
    '-webkit-line-clamp': '2',
    '-webkit-box-orient': 'vertical',
    'overflow': 'hidden',
  }),

  // -------------------------------------------------------------- gallery --
  css('.sc-gallery').styles(raw: {
    'position': 'fixed',
    'inset': '0',
    'z-index': '60',
    'display': 'flex',
    'align-items': 'center',
    'justify-content': 'center',
    'gap': '12px',
    'padding': '56px 16px 16px',
    'background': 'rgba(0, 0, 0, 0.88)',
  }),
  css('.sc-gallery__image').styles(raw: {
    'max-width': '100%',
    'max-height': '100%',
    'object-fit': 'contain',
    'border-radius': '8px',
  }),
  css('.sc-gallery__toolbar').styles(raw: {
    'position': 'absolute',
    'top': '12px',
    'right': '12px',
    'left': '12px',
    'display': 'flex',
    'align-items': 'center',
    'justify-content': 'flex-end',
    'gap': '8px',
    'color': '#fff',
  }),
  css('.sc-gallery__counter').styles(raw: {
    'margin-right': 'auto',
    'font-size': '13px',
    'opacity': '0.8',
  }),
  css('.sc-gallery__button', [
    css('&').styles(raw: {
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
      'width': '36px',
      'height': '36px',
      'border': 'none',
      'border-radius': '50%',
      'background': 'rgba(255, 255, 255, 0.12)',
      'color': '#fff',
      'font-size': '18px',
      'cursor': 'pointer',
    }),
    css('&:hover').styles(raw: {'background': 'rgba(255, 255, 255, 0.24)'}),
  ]),
  css('.sc-gallery__nav', [
    css('&').styles(raw: {
      'flex': '0 0 auto',
      'width': '40px',
      'height': '40px',
      'border': 'none',
      'border-radius': '50%',
      'background': 'rgba(255, 255, 255, 0.12)',
      'color': '#fff',
      'font-size': '20px',
      'cursor': 'pointer',
    }),
    css('&:hover').styles(raw: {'background': 'rgba(255, 255, 255, 0.24)'}),
  ]),

  // --------------------------------------------------------------- thread --
  css('.sc-thread').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'min-height': '0',
    'min-width': '0',
    'height': '100%',
    'border-left': '1px solid var(--sc-border)',
    'background': 'var(--sc-background)',
  }),
  css('.sc-thread__header').styles(raw: {
    'display': 'flex',
    'align-items': 'center',
    'justify-content': 'space-between',
    'gap': '12px',
    'padding': '12px 16px',
    'border-bottom': '1px solid var(--sc-border)',
    'flex': '0 0 auto',
  }),
  css('.sc-thread__parent').styles(raw: {
    'padding': '12px 16px',
    'border-bottom': '1px solid var(--sc-border)',
    'flex': '0 0 auto',
  }),
  css('.sc-thread__parent .sc-message-group__stack')
      .styles(raw: {'max-width': '100%'}),

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
  css('.sc-composer-wrap', [
    css('&').styles(raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'flex': '0 0 auto',
      'border-top': '1px solid var(--sc-border)',
    }),
    css('&.sc-composer-wrap--dragging')
        .styles(raw: {'background': 'var(--sc-surface)'}),
  ]),
  css('.sc-composer').styles(raw: {
    'display': 'flex',
    'align-items': 'flex-end',
    'gap': '8px',
    'padding': '12px 16px',
  }),
  css('.sc-composer__input', [
    css('&').styles(raw: {
      'flex': '1 1 auto',
      'min-width': '0',
      'padding': '10px 14px',
      'border-radius': '18px',
      'border': '1px solid var(--sc-border)',
      'background': 'var(--sc-surface)',
      'color': 'var(--sc-text-primary)',
      'font': 'inherit',
      'font-size': '15px',
      'line-height': '1.4',
      'outline': 'none',
      'resize': 'none',
      // Grown to fit its content by the composer, capped here so a long draft
      // cannot push the message list off screen.
      'max-height': '160px',
      'overflow-y': 'auto',
    }),
    css('&:focus').styles(raw: {
      'border-color': 'var(--sc-primary)',
      'background': 'var(--sc-background)',
    }),
    css('&::placeholder').styles(raw: {'color': 'var(--sc-text-secondary)'}),
    css('&:disabled').styles(raw: {'opacity': '0.6', 'cursor': 'not-allowed'}),
  ]),
  css('.sc-composer__attach', [
    css('&').styles(raw: {
      'flex': '0 0 auto',
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
      'width': '40px',
      'height': '40px',
      'border-radius': '50%',
      'color': 'var(--sc-text-secondary)',
      'font-size': '20px',
      'cursor': 'pointer',
    }),
    css('&:hover').styles(raw: {
      'background': 'var(--sc-surface-hover)',
      'color': 'var(--sc-text-primary)',
    }),
    css('&:focus-within').styles(raw: {
      'outline': '2px solid var(--sc-primary)',
      'outline-offset': '2px',
    }),
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
    css('&.sc-composer__send--wide').styles(raw: {
      'width': 'auto',
      'padding': '0 16px',
      'border-radius': '20px',
      'font': 'inherit',
      'font-size': '14px',
      'font-weight': '600',
    }),
    css('&:hover:not(:disabled)')
        .styles(raw: {'background': 'var(--sc-primary-hover)'}),
    css('&:disabled').styles(raw: {'opacity': '0.4', 'cursor': 'default'}),
    css('& svg').styles(raw: {'width': '20px', 'height': '20px'}),
  ]),
  css('.sc-composer__banner', [
    css('&').styles(raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': '10px',
      'padding': '8px 16px',
      'background': 'var(--sc-surface)',
      'border-bottom': '1px solid var(--sc-border)',
      'font-size': '13px',
      'color': 'var(--sc-text-secondary)',
    }),
    css('&.sc-composer__banner--error').styles(raw: {
      'color': 'var(--sc-danger)',
    }),
    css('& .sc-icon').styles(raw: {'font-size': '16px'}),
  ]),
  css('.sc-composer__banner-body').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'min-width': '0',
    'flex': '1 1 auto',
  }),
  css('.sc-composer__banner-close', [
    css('&').styles(raw: {
      'margin-left': 'auto',
      'flex': '0 0 auto',
      'width': '24px',
      'height': '24px',
      'padding': '0',
      'border': 'none',
      'border-radius': '6px',
      'background': 'transparent',
      'color': 'inherit',
      'font-size': '15px',
      'cursor': 'pointer',
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
    }),
    css('&:hover').styles(raw: {'background': 'var(--sc-surface-hover)'}),
  ]),
  css('.sc-composer__thumbs').styles(raw: {
    'display': 'flex',
    'flex-wrap': 'wrap',
    'gap': '8px',
    'padding': '10px 16px 0',
  }),
  css('.sc-composer__thumb').styles(raw: {
    'position': 'relative',
    'width': '72px',
    'height': '72px',
    'border-radius': '10px',
    'overflow': 'hidden',
    'background': 'var(--sc-surface)',
    'border': '1px solid var(--sc-border)',
  }),
  css('.sc-composer__thumb-image').styles(raw: {
    'width': '100%',
    'height': '100%',
    'object-fit': 'cover',
    'display': 'block',
  }),
  css('.sc-composer__thumb-file').styles(raw: {
    'display': 'flex',
    'flex-direction': 'column',
    'align-items': 'center',
    'justify-content': 'center',
    'gap': '3px',
    'height': '100%',
    'padding': '6px',
    'font-size': '10px',
    'text-align': 'center',
    'color': 'var(--sc-text-secondary)',
    'overflow': 'hidden',
  }),
  css('.sc-composer__thumb-file .sc-icon').styles(raw: {'font-size': '20px'}),
  css('.sc-composer__thumb-remove', [
    css('&').styles(raw: {
      'position': 'absolute',
      'top': '3px',
      'right': '3px',
      'width': '20px',
      'height': '20px',
      'padding': '0',
      'border': 'none',
      'border-radius': '50%',
      'background': 'rgba(0, 0, 0, 0.6)',
      'color': '#fff',
      'font-size': '13px',
      'cursor': 'pointer',
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
    }),
    css('&:hover').styles(raw: {'background': 'rgba(0, 0, 0, 0.8)'}),
  ]),
  css('.sc-composer__dropzone').styles(raw: {
    'position': 'absolute',
    'inset': '0',
    'z-index': '20',
    'display': 'flex',
    'align-items': 'center',
    'justify-content': 'center',
    'border': '2px dashed var(--sc-primary)',
    'border-radius': '12px',
    'background':
        'color-mix(in srgb, var(--sc-primary) 10%, var(--sc-background))',
    'color': 'var(--sc-primary)',
    'font-size': '14px',
    'font-weight': '600',
    'pointer-events': 'none',
  }),
  css('.sc-composer__show-in-channel').styles(raw: {
    'display': 'flex',
    'align-items': 'center',
    'gap': '8px',
    'padding': '0 16px 10px',
    'font-size': '13px',
    'color': 'var(--sc-text-secondary)',
    'cursor': 'pointer',
  }),

  // --------------------------------------------------------- autocomplete --
  css('.sc-autocomplete').styles(raw: {
    'position': 'absolute',
    'left': '12px',
    'right': '12px',
    'bottom': 'calc(100% + 6px)',
    'z-index': '35',
    'max-height': '240px',
    'overflow-y': 'auto',
    'padding': '6px',
    'border': '1px solid var(--sc-border)',
    'border-radius': '12px',
    'background': 'var(--sc-background)',
    'box-shadow': '0 12px 32px rgba(0, 0, 0, 0.18)',
  }),
  css('.sc-autocomplete__heading').styles(raw: {
    'padding': '4px 8px',
    'font-size': '11px',
    'font-weight': '700',
    'text-transform': 'uppercase',
    'letter-spacing': '0.05em',
    'color': 'var(--sc-text-secondary)',
  }),
  css('.sc-autocomplete__option', [
    css('&').styles(raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'width': '100%',
      'padding': '6px 8px',
      'border': 'none',
      'border-radius': '8px',
      'background': 'transparent',
      'color': 'var(--sc-text-primary)',
      'font': 'inherit',
      'font-size': '14px',
      'text-align': 'left',
      'cursor': 'pointer',
    }),
    css('&:hover').styles(raw: {'background': 'var(--sc-surface-hover)'}),
    // The first option is what Enter and Tab accept, so it reads as preselected.
    css('&:first-of-type').styles(raw: {'background': 'var(--sc-surface)'}),
  ]),
  css('.sc-autocomplete__command').styles(raw: {
    'font-weight': '600',
    'color': 'var(--sc-primary)',
  }),
  css('.sc-autocomplete__description').styles(raw: {
    'color': 'var(--sc-text-secondary)',
    'font-size': '13px',
    'white-space': 'nowrap',
    'overflow': 'hidden',
    'text-overflow': 'ellipsis',
  }),

  // ------------------------------------------------------------- indicators --
  css('.sc-typing').styles(raw: {
    'display': 'flex',
    'align-items': 'center',
    'gap': '6px',
    'height': '20px',
    'padding': '0 18px 4px',
    'font-size': '12px',
    'color': 'var(--sc-text-secondary)',
    'flex': '0 0 auto',
  }),
  css('.sc-typing__dots').styles(raw: {'display': 'flex', 'gap': '3px'}),
  css('.sc-typing__dots span').styles(raw: {
    'width': '5px',
    'height': '5px',
    'border-radius': '50%',
    'background': 'currentColor',
    'animation': 'sc-bounce 1200ms ease-in-out infinite',
  }),
  css('.sc-typing__dots span:nth-child(2)')
      .styles(raw: {'animation-delay': '150ms'}),
  css('.sc-typing__dots span:nth-child(3)')
      .styles(raw: {'animation-delay': '300ms'}),
  StyleRule.keyframes(name: 'sc-bounce', styles: {
    '0%, 60%, 100%': Styles(raw: {'opacity': '0.35'}),
    '30%': Styles(raw: {'opacity': '1'}),
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

  // Respect a reduced-motion preference for everything that loops.
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
    css('.sc-spinner, .sc-typing__dots span, .sc-progress__fill')
        .styles(raw: {'animation': 'none'}),
  ]),
];
