import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import 'presentation/pages/trip_map_page.dart';

void main() {
  runApp(const ProviderScope(child: MapsPreviewApp()));
}

class MapsPreviewApp extends StatelessWidget {
  const MapsPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCar Maps Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const TripMapPage(),
    );
  }
}
