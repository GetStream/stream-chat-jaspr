import 'package:jaspr/dom.dart';

/// Styles for the example app's own chrome — the sign-in screen and the
/// sidebar header. Everything inside the chat surface is styled by
/// `streamChatStyles` from the SDK.
final List<StyleRule> appStyles = [
  css('.app-signin').styles(raw: {
    'display': 'flex',
    'align-items': 'center',
    'justify-content': 'center',
    'height': '100%',
    'padding': '24px',
  }),
  css('.app-signin__card').styles(raw: {
    'width': 'min(420px, 100%)',
    'padding': '28px',
    'border': '1px solid var(--sc-border)',
    'border-radius': '16px',
    'background': 'var(--sc-background)',
    'box-shadow': '0 10px 40px rgb(0 0 0 / 8%)',
  }),
  css('.app-signin__title').styles(raw: {
    'margin': '0 0 4px',
    'font-size': '20px',
    'font-weight': '700',
  }),
  css('.app-signin__subtitle').styles(raw: {
    'margin': '0 0 20px',
    'color': 'var(--sc-text-secondary)',
    'font-size': '14px',
    'line-height': '1.5',
  }),
  css('.app-account', [
    css('&').styles(raw: {
      'display': 'block',
      'width': '100%',
      'text-align': 'left',
      'padding': '12px 14px',
      'margin-bottom': '10px',
      'border': '1px solid var(--sc-border)',
      'border-radius': '12px',
      'background': 'var(--sc-surface)',
      'color': 'inherit',
      'font': 'inherit',
      'cursor': 'pointer',
      'transition': 'border-color 120ms ease, background 120ms ease',
    }),
    css('&:hover:not(:disabled)').styles(raw: {
      'border-color': 'var(--sc-primary)',
      'background': 'var(--sc-surface-hover)',
    }),
    css('&:disabled').styles(raw: {'opacity': '0.5', 'cursor': 'default'}),
  ]),
  css('.app-account__label').styles(raw: {'font-weight': '600'}),
  css('.app-account__description').styles(raw: {
    'color': 'var(--sc-text-secondary)',
    'font-size': '13px',
    'margin-top': '2px',
  }),
  css('.app-sidebar-header').styles(raw: {
    'display': 'flex',
    'align-items': 'center',
    'gap': '10px',
    'padding': '12px 14px',
    'border-bottom': '1px solid var(--sc-border)',
    'flex': '0 0 auto',
  }),
  css('.app-sidebar-header__name').styles(raw: {
    'flex': '1 1 auto',
    'min-width': '0',
    'font-weight': '600',
    'white-space': 'nowrap',
    'overflow': 'hidden',
    'text-overflow': 'ellipsis',
  }),
  css('.app-icon-button', [
    css('&').styles(raw: {
      'flex': '0 0 auto',
      'width': '32px',
      'height': '32px',
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
      'border': 'none',
      'border-radius': '8px',
      'background': 'transparent',
      'color': 'var(--sc-text-secondary)',
      'cursor': 'pointer',
      'font-size': '16px',
      'line-height': '1',
    }),
    css('&:hover').styles(raw: {
      'background': 'var(--sc-surface-hover)',
      'color': 'var(--sc-text-primary)',
    }),
  ]),
  // The back button only makes sense once the two panes collapse into one.
  css('.app-back').styles(raw: {'display': 'none'}),
  css.media(MediaQuery.screen(maxWidth: Unit.pixels(760)), [
    css('.app-back').styles(raw: {'display': 'inline-flex'}),
  ]),
];
