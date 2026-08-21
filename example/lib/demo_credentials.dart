/// A set of credentials the example app can connect with.
class DemoCredentials {
  /// Creates a credential set.
  const DemoCredentials({
    required this.label,
    required this.description,
    required this.apiKey,
    required this.userId,
    required this.token,
  });

  /// Name shown on the sign-in button.
  final String label;

  /// One-line explanation of what this account contains.
  final String description;

  /// The Stream application API key.
  final String apiKey;

  /// The user to connect as.
  final String userId;

  /// A developer token for [userId].
  final String token;
}

/// Public demo accounts, the same ones the Flutter SDK tutorials use.
///
/// The tokens are long lived and intentionally committed — they belong to
/// Stream's public sandbox apps and grant access to nothing else. A real app
/// must mint tokens server-side with its API secret, which must never reach
/// the browser.
const List<DemoCredentials> demoCredentials = [
  DemoCredentials(
    label: 'Sample app user',
    description: 'Several channels with history — best for trying the list.',
    apiKey: 's2dxdhpxd94g',
    userId: 'super-band-9',
    token:
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoic3VwZXItYmFuZC05In0.0L6lGoeLwkz0aZRUcpZKsvaXtNEDHBcezVTZ0oPq40A',
  ),
  DemoCredentials(
    label: 'Tutorial user',
    description: 'The single #flutterdevs channel from the tutorial.',
    apiKey: 'b67pax5b2wdq',
    userId: 'tutorial-flutter',
    token:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidHV0b3JpYWwtZmx1dHRlciJ9.S-MJpoSwDiqyXpUURgO5wVqJ4vKlIVFLSEyrFYCOE1c',
  ),
];
