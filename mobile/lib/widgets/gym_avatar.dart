import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// A gym logo or fallback-initial avatar, mirroring the web `GymAvatar`.
///
/// Shows the base64 `logo` image when present; otherwise renders the gym
/// name's first letter on a `primaryColor` (default orange) background.
class GymAvatar extends StatelessWidget {
  const GymAvatar({
    super.key,
    required this.name,
    this.logo,
    this.primaryColor,
    this.size = 48,
  });

  final String name;
  final String? logo;
  final String? primaryColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget? logoWidget = _buildLogo();
    if (logoWidget != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: SizedBox(width: size, height: size, child: logoWidget),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _parseHex(primaryColor ?? '#f97316'),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.characters.first.toUpperCase() : 'G',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.42,
        ),
      ),
    );
  }

  Widget? _buildLogo() {
    final String raw = logo ?? '';
    if (raw.isEmpty) return null;
    try {
      final String base64 = raw.contains(',') ? raw.split(',').last : raw;
      final Uint8List bytes = base64Decode(base64);
      return Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
    } catch (_) {
      return null;
    }
  }

  static Color _parseHex(String hex) {
    var value = hex.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 6) value = 'FF$value';
    if (value.length == 8) {
      final int? parsed = int.tryParse(value, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return const Color(0xFFF97316);
  }
}
