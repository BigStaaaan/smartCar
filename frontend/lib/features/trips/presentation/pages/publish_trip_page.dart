import 'package:flutter/material.dart';

import '../../../vehicles/presentation/vehicle_theme.dart';
import 'trip_form.dart';

class PublishTripPage extends StatelessWidget {
  const PublishTripPage({super.key, this.isPreview = false});

  final bool isPreview;

  @override
  Widget build(BuildContext context) => Theme(
        data: vehicleTheme(),
        child: Scaffold(
          backgroundColor: vehicleCream,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: TripForm(isPreview: isPreview),
              ),
            ),
          ),
        ),
      );
}
