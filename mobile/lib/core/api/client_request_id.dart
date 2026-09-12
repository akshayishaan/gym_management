import 'dart:math';

/// Creates an RFC 4122 version 4 UUID for idempotent client mutations.
///
/// Mirrors the web `lib/clientRequestId.ts`. [Random.secure] is the
/// cryptographically-strong source available on all Dart platforms, so there is
/// no need for the web's `crypto.randomUUID`/`getRandomValues` fallback chain —
/// a single secure source covers every path.
String createRequestId() {
  final Random random = Random.secure();
  final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));

  // RFC 4122 version 4 and variant bits.
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx (8/9/a/b)

  final String hex =
      bytes.map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}
