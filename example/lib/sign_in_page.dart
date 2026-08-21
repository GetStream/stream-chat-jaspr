import 'package:jaspr/dom.dart' hide Filter;
import 'package:jaspr/jaspr.dart';

import 'demo_credentials.dart';

/// Account picker shown before a client is connected.
class SignInPage extends StatelessComponent {
  /// Creates the sign-in page.
  const SignInPage({
    required this.onSignIn,
    this.isConnecting = false,
    this.error,
    super.key,
  });

  /// Called when an account is chosen.
  final void Function(DemoCredentials credentials) onSignIn;

  /// Whether a connection attempt is in flight.
  final bool isConnecting;

  /// The last connection error, if any.
  final Object? error;

  @override
  Component build(BuildContext context) {
    return div(
      [
        div(
          [
            h1(
              [Component.text('Stream Chat for Jaspr')],
              classes: 'app-signin__title',
            ),
            p(
              [Component.text(
                'An experimental port of the Stream Chat UI to Jaspr. '
                'Pick a public demo account to connect.',
              )],
              classes: 'app-signin__subtitle',
            ),
            for (final credentials in demoCredentials)
              button(
                [
                  div(
                    [Component.text(credentials.label)],
                    classes: 'app-account__label',
                  ),
                  div(
                    [Component.text(credentials.description)],
                    classes: 'app-account__description',
                  ),
                ],
                type: ButtonType.button,
                disabled: isConnecting,
                classes: 'app-account',
                onClick: () => onSignIn(credentials),
              ),
            if (isConnecting) div([], classes: 'sc-spinner'),
            if (error case final error?)
              div(
                [Component.text('Could not connect: $error')],
                classes: 'sc-error',
              ),
          ],
          classes: 'app-signin__card',
        ),
      ],
      classes: 'app-signin',
    );
  }
}
