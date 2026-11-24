import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'vehicle_theme.dart';

final vehicleImagePickerProvider = Provider<
    Future<Uint8List?> Function(ImageSource source,
        {required double maxDimension})>(
  (ref) {
    final picker = ImagePicker();
    return (source, {required maxDimension}) async {
      final image = await picker.pickImage(
        source: source,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        imageQuality: 88,
        requestFullMetadata: false,
      );
      if (image == null) return null;
      if (await image.length() > 8 * 1024 * 1024) {
        throw const FormatException('Image exceeds 8 MiB.');
      }
      return image.readAsBytes();
    };
  },
);

class VehicleImagePreview extends StatelessWidget {
  const VehicleImagePreview({
    super.key,
    required this.bytes,
    required this.label,
    this.fit = BoxFit.contain,
    this.expandable = false,
  });

  final Uint8List bytes;
  final String label;
  final BoxFit fit;
  final bool expandable;

  Widget _image(BoxFit fit) => Image.memory(
        bytes,
        fit: fit,
        semanticLabel: label,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_outlined,
              semanticLabel: 'Image illisible'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: driverOutline.withValues(alpha: .24),
        child: SizedBox.expand(child: _image(fit)),
      ),
    );
    if (!expandable) return image;
    return Semantics(
      button: true,
      label: 'Agrandir : $label',
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: IconButton(
                    tooltip: 'Fermer l’aperçu',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * .55,
                  width: double.infinity,
                  child: InteractiveViewer(child: _image(BoxFit.contain)),
                ),
              ],
            ),
          ),
        ),
        child: image,
      ),
    );
  }
}
