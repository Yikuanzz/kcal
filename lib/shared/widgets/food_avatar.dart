import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class FoodAvatar extends StatefulWidget {
  const FoodAvatar({super.key, required this.imageBase64, this.size = 52});

  final String? imageBase64;
  final double size;

  @override
  State<FoodAvatar> createState() => _FoodAvatarState();
}

class _FoodAvatarState extends State<FoodAvatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant FoodAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBase64 != widget.imageBase64) {
      _decode();
    }
  }

  void _decode() {
    final raw = widget.imageBase64;
    if (raw == null || raw.isEmpty) {
      _bytes = null;
      return;
    }
    try {
      _bytes = base64Decode(raw);
    } catch (_) {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size * 0.28),
      child: SizedBox.square(
        dimension: widget.size,
        child: bytes == null
            ? const ColoredBox(
                color: Color(0xFFF3D7C6),
                child: Icon(Icons.rice_bowl, color: KcalColors.persimmonDark),
              )
            : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}
