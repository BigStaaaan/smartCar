import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcar/app/app.dart';
import 'package:smartcar/features/authentication/presentation/pages/login_page.dart';

void main() {
  testWidgets('SmartCar welcome screen navigates to LoginPage on Get Started tap',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: SmartCarApp()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('SmartCar'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify Login page is rendered
    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Campus Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Stay signed in on this phone'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Create one'), findsOneWidget);
  });

  testWidgets('LoginPage validates university email and password properly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Tap Log In with empty fields
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your campus email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    // Enter non-university email
    await tester.enterText(
      find.byType(TextFormField).first,
      'test@gmail.com',
    );
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Please use your verified .edu campus email'), findsOneWidget);

    // Toggle password visibility
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    // Toggle Remember Me switch
    expect(find.text('Stay signed in on this phone'), findsOneWidget);
    await tester.tap(find.text('Stay signed in on this phone'));
    await tester.pump();
  });

  testWidgets('LoginPage adapts to small screen with zero overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
