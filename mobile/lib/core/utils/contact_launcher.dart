import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Hands a `tel:` / `sms:` / `https://wa.me/...` URL to the platform
/// (dialer, messaging app, WhatsApp). Used by the WhatsApp/SMS/Call quick
/// actions on the Member Detail and Dashboard screens — the backend has no
/// contact API, so these are device-native intents, not HTTP calls.
///
/// Shows a snackbar instead of throwing when no app can handle the URL
/// (e.g. WhatsApp isn't installed, or this is an emulator with no dialer).
Future<void> launchContactUrl(BuildContext context, String url) async {
  try {
    final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app found to handle that action.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app found to handle that action.')),
      );
    }
  }
}
