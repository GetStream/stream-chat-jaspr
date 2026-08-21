import 'dart:async';
import 'dart:typed_data';

import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

/// Browser plumbing that the components need but that Jaspr does not wrap.
///
/// Everything here goes through `package:universal_web`, whose VM variants
/// throw rather than fail to compile. That keeps the package analysable and
/// compilable for the Dart VM, which matters because Jaspr can render on the
/// server, while still giving real implementations in the browser. None of
/// these functions run during server rendering: they are only ever reached
/// from event handlers and `initState` on the client.

/// Reads [file] fully into memory.
///
/// Stream's upload API takes bytes rather than a stream, so there is no
/// benefit to chunking here.
Future<Uint8List> readFileBytes(web.File file) {
  final reader = web.FileReader();
  final completer = Completer<Uint8List>();

  reader.addEventListener(
    'load',
    ((web.Event _) {
      final buffer = reader.result as JSArrayBuffer?;
      if (buffer == null) {
        completer.completeError(StateError('Could not read ${file.name}.'));
        return;
      }
      completer.complete(buffer.toDart.asUint8List());
    }).toJS,
  );
  reader.addEventListener(
    'error',
    ((web.Event _) {
      completer.completeError(StateError('Could not read ${file.name}.'));
    }).toJS,
  );

  reader.readAsArrayBuffer(file);
  return completer.future;
}

/// Creates a temporary URL that renders [file] without uploading it first.
///
/// Used for local attachment previews. Release it with [revokeObjectUrl] once
/// the preview is gone, otherwise the blob is retained for the lifetime of the
/// document.
String createObjectUrl(web.Blob file) => web.URL.createObjectURL(file);

/// Releases a URL previously returned by [createObjectUrl].
void revokeObjectUrl(String url) => web.URL.revokeObjectURL(url);

/// Copies [text] to the system clipboard.
///
/// Returns `false` when the browser refuses, which happens on insecure origins
/// and when the call is not tied to a user gesture.
Future<bool> copyToClipboard(String text) async {
  try {
    await web.window.navigator.clipboard.writeText(text).toDart;
    return true;
  } catch (_) {
    return false;
  }
}

/// Calls [callback] when Escape is pressed anywhere in the document.
///
/// Returns a disposer. Overlays use this instead of a key handler on their own
/// element so that Escape works regardless of where focus currently sits.
void Function() onEscapePressed(void Function() callback) {
  final listener = ((web.Event event) {
    if ((event as web.KeyboardEvent).key == 'Escape') callback();
  }).toJS;

  web.document.addEventListener('keydown', listener);
  return () => web.document.removeEventListener('keydown', listener);
}

/// Files carried by a drag or paste event, in document order.
List<web.File> filesFromDataTransfer(web.DataTransfer? transfer) {
  final list = transfer?.files;
  if (list == null) return const [];
  return [for (var i = 0; i < list.length; i++) ?list.item(i)];
}

/// Files chosen in an `<input type="file">`.
List<web.File> filesFromInput(web.HTMLInputElement input) {
  final list = input.files;
  if (list == null) return const [];
  return [for (var i = 0; i < list.length; i++) ?list.item(i)];
}

/// Whether [event] carries files, as opposed to dragged text or a selection.
bool dragCarriesFiles(web.DragEvent event) {
  final types = event.dataTransfer?.types;
  if (types == null) return false;
  for (var i = 0; i < types.length; i++) {
    if (types.toDart[i].toDart == 'Files') return true;
  }
  return false;
}

/// Triggers a download of [url] under [filename] without navigating away.
void downloadUrl(String url, String filename) {
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.rel = 'noopener noreferrer';
  anchor.style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
