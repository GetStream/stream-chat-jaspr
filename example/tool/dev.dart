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
//   dart run tool/dev.dart --host any   # also reachable from other devices
//   dart run tool/dev.dart --release --output build  # publishable directory
//
// Once jaspr_web_compilers supports the current SDK, this can be replaced by
// `jaspr serve` and deleted.
import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:watcher/watcher.dart';

const _source = 'web';
const _entrypoint = 'web/main.dart';
const _output = 'web/main.dart.js';

Future<void> main(List<String> args) async {
  final isRelease = args.contains('--release');
  final port = _intArg(args, '--port') ?? 8080;
  // `--output` writes a self-contained directory to publish, leaving out the
  // Dart sources and the compiler's sidecar files. It implies `--no-serve`.
  final publishTo = _stringArg(args, '--output');
  final shouldServe = !args.contains('--no-serve') && publishTo == null;
  // `--host any` binds every interface so phones and tablets on the same
  // network can reach the app, which is the only way to exercise the narrow
  // layout on a real device.
  final bindAnyHost = _stringArg(args, '--host') == 'any';

  final ok = await _compile(isRelease: isRelease);
  if (!ok) {
    if (isRelease || publishTo != null) exitCode = 1;
    if (publishTo != null) return;
  }

  if (publishTo != null) {
    _publish(publishTo);
    return;
  }

  if (!shouldServe) return;

  final handler = const Pipeline()
      .addMiddleware(_noCache)
      .addHandler(createStaticHandler('web', defaultDocument: 'index.html'));

  final address = bindAnyHost ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4;
  final server = await shelf_io.serve(handler, address, port);

  stdout.writeln('Serving http://localhost:${server.port}');
  if (bindAnyHost) {
    for (final ip in await _localAddresses()) {
      stdout.writeln('         http://$ip:${server.port}');
    }
  }

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

/// Copies the built app into [destination], ready to be served as static files.
///
/// Only the compiled bundle and the hand-written assets go across. The Dart
/// entrypoint and the compiler's `.map` and `.deps` sidecars stay behind.
void _publish(String destination) {
  final target = Directory(destination);
  if (target.existsSync()) target.deleteSync(recursive: true);
  target.createSync(recursive: true);

  var copied = 0;
  for (final entity in Directory(_source).listSync()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    const skipped = ['.dart', '.js.map', '.js.deps'];
    if (skipped.any(name.endsWith)) continue;
    entity.copySync('$destination/$name');
    copied++;
  }

  // Without this GitHub Pages runs the output through Jekyll, which drops
  // files and directories whose names begin with an underscore.
  File('$destination/.nojekyll').writeAsStringSync('');

  stdout.writeln('Published $copied files to $destination');
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

/// Non-loopback IPv4 addresses this machine can be reached on.
Future<List<String>> _localAddresses() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  return [
    for (final interface in interfaces)
      for (final address in interface.addresses) address.address,
  ];
}

String? _stringArg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

int? _intArg(List<String> args, String name) {
  final value = _stringArg(args, name);
  return value == null ? null : int.tryParse(value);
}
