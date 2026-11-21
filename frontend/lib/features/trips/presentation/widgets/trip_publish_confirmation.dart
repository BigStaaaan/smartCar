import 'package:flutter/material.dart';

import '../../../vehicles/presentation/vehicle_form_art.dart';

class TripPublishConfirmation extends StatelessWidget {
  const TripPublishConfirmation({
    super.key,
    required this.isPreview,
    required this.onDone,
  });

  final bool isPreview;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const VehicleSaveCheck(),
            const SizedBox(height: 14),
            Text('Trajet publié',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 30)),
            const SizedBox(height: 8),
            if (isPreview)
              const Text('Enregistré dans le Preview local',
                  textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onDone, child: const Text('Terminer')),
          ]),
        ),
      );
}
