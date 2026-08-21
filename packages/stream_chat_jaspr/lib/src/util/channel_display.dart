import 'package:stream_chat/stream_chat.dart';

/// A human readable title for [channel].
///
/// Explicitly named channels use their name. Unnamed ones — which is what the
/// API returns for direct conversations — are titled after the other
/// participants, since "!members-Ku6lJ..." is not something to show a user.
String channelDisplayName(Channel channel, {String? currentUserId}) {
  final name = channel.name;
  if (name != null && name.isNotEmpty) return name;

  final others = channel.state?.members
          .where((it) => it.userId != currentUserId)
          .map((it) => it.user?.name ?? it.userId)
          .whereType<String>()
          .toList() ??
      const <String>[];

  if (others.isEmpty) return channel.id ?? 'Channel';
  if (others.length <= 3) return others.join(', ');
  return '${others.take(2).join(', ')} and ${others.length - 2} others';
}

/// A one-line preview of [message], as shown in the channel list.
String messagePreview(Message? message, {String? currentUserId}) {
  if (message == null) return 'No messages yet';
  if (message.isDeleted) return 'This message was deleted';

  final body = switch (message) {
    _ when (message.text ?? '').isNotEmpty => message.text!,
    _ when message.attachments.isNotEmpty =>
      _attachmentPreview(message.attachments),
    _ => 'Message',
  };

  final flattened = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  final author = message.user;
  if (author == null) return flattened;
  if (author.id == currentUserId) return 'You: $flattened';
  return '${author.name}: $flattened';
}

String _attachmentPreview(List<Attachment> attachments) {
  final type = attachments.first.type;
  final label = switch (type) {
    AttachmentType.image => 'Photo',
    AttachmentType.video => 'Video',
    AttachmentType.audio || AttachmentType.voiceRecording => 'Audio',
    AttachmentType.giphy => 'GIF',
    _ => 'Attachment',
  };
  if (attachments.length == 1) return label;
  return '$label +${attachments.length - 1}';
}
