// Build-and-serve script for the example app.
//
// This exists because `jaspr serve` cannot be used on this toolchain:
// jaspr_web_compilers is capped at Dart <3.11 and we are on 3.13. The app
// deliberately uses no jaspr_builder codegen (no `@client`, `@css`, or
// `@Import` annotations), so `dart compile js` is all that is actually needed.
//
//   dart run tool/dev.dart              # build, serve on :8080, rebuild on change
//   dart run tool/dev.dart --release    # optimised one-off build, no watching
//   dart run tool/dev.dart --port 3000
//
// Once jaspr_web_compilers supports the current SDK, this can be replaced by
// `jaspr serve` and deleted.
import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:watcher/watcher.dart';

const _entrypoint = 'web/main.dart';
const _output = 'web/main.dart.js';

Future<void> main(List<String> args) async {
  final isRelease = args.contains('--release');
  final port = _intArg(args, '--port') ?? 8080;
  final shouldServe = !args.contains('--no-serve');

  final ok = await _compile(isRelease: isRelease);
  if (!ok && isRelease) exitCode = 1;
  if (!shouldServe) return;

  final handler = const Pipeline()
      .addMiddleware(_noCache)
      .addHandler(createStaticHandler('web', defaultDocument: 'index.html'));

  final server = await shelf_io.serve(handler, 'localhost', port);
  stdout.writeln('Serving http://${server.address.host}:${server.port}');

  if (isRelease) return;
  stdout.writeln('Watching for changes. Ctrl-C to stop.');
  await _watch(() => _compile(isRelease: false));
}

Future<bool> _compile({required bool isRelease}) async {
  final stopwatch = Stopwatch()..start();
  stdout.writeln(isRelease ? 'Building (release)…' : 'Building…');

  final result = await Process.run(Platform.resolvedExecutable, [
    'compile',
    'js',
    if (isRelease) '-O2' else ...['-O1', '--enable-asserts'],
    '-o',
    _output,
    _entrypoint,
  ]);

  stopwatch.stop();
  if (result.exitCode != 0) {
    stderr
      ..writeln('Build failed:')
      ..writeln(result.stdout)
      ..writeln(result.stderr);
    return false;
  }

  final size = File(_output).lengthSync() / (1024 * 1024);
  stdout.writeln(
    'Built in ${stopwatch.elapsedMilliseconds}ms '
    '(${size.toStringAsFixed(1)} MB)',
  );
  return true;
}

/// Rebuilds on any Dart change in this app or in the SDK package.
Future<void> _watch(Future<bool> Function() rebuild) async {
  final roots = [
    'lib',
    'web',
    '../packages/stream_chat_jaspr/lib',
  ].where((it) => Directory(it).existsSync());

  Timer? debounce;
  var isBuilding = false;

  void schedule() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 150), () async {
      if (isBuilding) return;
      isBuilding = true;
      try {
        await rebuild();
      } finally {
        isBuilding = false;
      }
    });
  }

  for (final root in roots) {
    DirectoryWatcher(root).events.listen((event) {
      // Ignore our own compiler output, which lives inside a watched directory.
      if (event.path.endsWith('.js') ||
          event.path.endsWith('.js.map') ||
          event.path.endsWith('.js.deps')) {
        return;
      }
      if (!event.path.endsWith('.dart')) return;
      schedule();
    });
  }

  await Completer<void>().future;
}

Handler Function(Handler) get _noCache => (innerHandler) {
      return (request) async {
        final response = await innerHandler(request);
        return response.change(headers: {'cache-control': 'no-store'});
      };
    };

int? _intArg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return int.tryParse(args[index + 1]);
}
