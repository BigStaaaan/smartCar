import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import 'presentation/pages/conversations_page.dart';

void main() {
  runApp(const ProviderScope(child: MessagingPreviewApp()));
}

class MessagingPreviewApp extends StatelessWidget {
  const MessagingPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCar Messaging Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ConversationsPage(),
    );
  }
}
