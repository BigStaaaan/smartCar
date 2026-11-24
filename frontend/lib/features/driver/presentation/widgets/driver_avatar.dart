import 'package:flutter/material.dart';

import '../../../vehicles/presentation/vehicle_theme.dart';

class DriverAvatar extends StatelessWidget {
  const DriverAvatar(
    this.initial, {
    super.key,
    this.photoUrl,
    this.size = 36,
    this.fontSize,
    this.background = driverHighlight,
    this.foreground = driverText,
  });

  final String initial;
  final String? photoUrl;
  final double size;
  final double? fontSize;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      initial,
      style: TextStyle(
          color: foreground, fontWeight: FontWeight.w800, fontSize: fontSize),
    );
    final url = Uri.tryParse(photoUrl?.trim() ?? '');
    final hasPhoto = url != null &&
        (url.scheme == 'https' || url.scheme == 'http') &&
        url.host.isNotEmpty;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: driverSurface, width: 2),
      ),
      child: hasPhoto
          ? ClipOval(
              child: SizedBox.expand(
                child: Image.network(
                  url.toString(),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) =>
                          frame == null ? Center(child: fallback) : child,
                  errorBuilder: (context, error, stackTrace) =>
                      Center(child: fallback),
                ),
              ),
            )
          : fallback,
    );
  }
}
