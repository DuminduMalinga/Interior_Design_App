import 'dart:typed_data';
import 'dart:ui' as ui;

/// Profile-picture rules, matching the web's `avatar.ts`.
const avatarExtensions = ['jpg', 'jpeg', 'png', 'webp'];
const avatarMaxPickedBytes = 10 * 1024 * 1024;

/// Pictures are shown small, so they are scaled down before they are stored
/// (the `avatars` bucket takes at most 2 MB).
const avatarMaxSidePx = 512;

/// Why a picked file cannot be a profile picture, or null when it can.
String? checkAvatarFile({required String extension, required int? size}) {
  if (!avatarExtensions.contains(extension.toLowerCase())) {
    return 'Choose a JPEG, PNG or WebP picture.';
  }
  if (size != null && size > avatarMaxPickedBytes) {
    return 'That picture is larger than 10 MB. Choose a smaller one.';
  }
  return null;
}

/// The MIME type for a picture's file extension.
String avatarContentType(String extension) => switch (extension.toLowerCase()) {
  'png' => 'image/png',
  'webp' => 'image/webp',
  _ => 'image/jpeg',
};

/// The file extension for a MIME type, as the web names the stored file.
String avatarExtension(String contentType) => switch (contentType) {
  'image/png' => 'png',
  'image/webp' => 'webp',
  _ => 'jpg',
};

/// The size a picture is scaled to so its longer side is at most
/// [avatarMaxSidePx]; never enlarged.
({int width, int height}) avatarTargetSize(int width, int height) {
  final scale = avatarMaxSidePx / (width > height ? width : height);
  if (scale >= 1) return (width: width, height: height);
  return (
    width: (width * scale).round().clamp(1, avatarMaxSidePx),
    height: (height * scale).round().clamp(1, avatarMaxSidePx),
  );
}

/// The picture scaled down to fit [avatarMaxSidePx], as PNG (the only format
/// Flutter can encode); the original when it cannot be read, as the web does.
Future<({Uint8List bytes, String contentType})> shrinkAvatar(
  Uint8List bytes,
  String contentType,
) async {
  final original = (bytes: bytes, contentType: contentType);
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size = avatarTargetSize(descriptor.width, descriptor.height);
    if (size.width == descriptor.width && size.height == descriptor.height) {
      // already small enough: keep the picture as it is
      descriptor.dispose();
      buffer.dispose();
      return original;
    }
    final codec = await descriptor.instantiateCodec(
      targetWidth: size.width,
      targetHeight: size.height,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    if (data == null || data.lengthInBytes == 0) return original;
    return (bytes: data.buffer.asUint8List(), contentType: 'image/png');
  } catch (_) {
    return original;
  }
}
