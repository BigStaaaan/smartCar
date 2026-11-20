import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcar/features/driver/presentation/pages/driver_dashboard_page.dart';

void main() {
  testWidgets('Driver dashboard animates the prototype statistics', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DriverDashboardPage()));
    expect(find.text('0,0'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1400));

    expect(find.text('Mode Driver'), findsOneWidget);
    expect(find.text('Gare Marrakech'), findsOneWidget);
    expect(find.text('2 places libres'), findsOneWidget);
    expect(find.text('4,8'), findsOneWidget);
    expect(find.text('Données de démonstration'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Driver dashboard fits a small screen with reduced motion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var publishTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: DriverDashboardPage(onPublish: () => publishTapped = true),
      ),
    );

    expect(find.text('4,8'), findsOneWidget);
    await tester.tap(find.byTooltip('Publier un trajet'));
    expect(publishTapped, isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
