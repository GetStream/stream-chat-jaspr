import 'dart:typed_data';

import 'package:stream_chat/stream_chat.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import 'dom.dart';

/// Object URLs for attachments that exist only in memory.
///
/// An attachment that has been picked but not yet uploaded has bytes and no
/// URL, so there is nothing for an `<img>` to point at. Wrapping the bytes in
/// a blob URL gives one, which is what lets a picked image appear instantly in
/// the composer and stay visible on the optimistic message while it uploads.
///
/// URLs are cached by attachment id because creating one on every render would
/// allocate a new blob each time and defeat the browser's image cache. Entries
/// are released by [releaseLocalPreview] once the real remote URL arrives.
final Map<String, String> _previews = {};

/// A displayable URL for [attachment], preferring the uploaded one.
///
/// Returns `null` when the attachment has neither a remote URL nor local
/// bytes, which is the case for a link preview that failed to enrich.
String? previewUrlFor(Attachment attachment) {
  final remote = attachment.imageUrl ??
      attachment.thumbUrl ??
      attachment.assetUrl ??
      attachment.ogScrapeUrl;
  if (remote != null) {
    // The upload finished, so the in-memory copy is dead weight.
    releaseLocalPreview(attachment.id);
    return remote;
  }

  final bytes = attachment.file?.bytes;
  if (bytes == null) return null;

  return _previews.putIfAbsent(
    attachment.id,
    () => blobUrlFromBytes(bytes, attachment.mimeType),
  );
}

/// Creates a blob URL that serves [bytes] as [mimeType].
String blobUrlFromBytes(Uint8List bytes, String? mimeType) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType ?? 'application/octet-stream'),
  );
  return createObjectUrl(blob);
}

/// Releases the cached preview for [attachmentId], if there is one.
void releaseLocalPreview(String attachmentId) {
  final url = _previews.remove(attachmentId);
  if (url != null) revokeObjectUrl(url);
}

/// Releases every cached preview. Intended for teardown in tests.
void releaseAllLocalPreviews() {
  for (final url in _previews.values) {
    revokeObjectUrl(url);
  }
  _previews.clear();
}
