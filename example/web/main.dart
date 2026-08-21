import 'package:jaspr/client.dart';
import 'package:stream_chat_jaspr_example/app.dart';

void main() {
  // No generated options: this app deliberately avoids jaspr_builder, so there
  // is nothing to register. See the repository README for why.
  Jaspr.initializeApp();
  runApp(const App());
}
