import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartcar/features/trips/data/repositories/demo_trip_repository.dart';
import 'package:smartcar/features/trips/presentation/providers/trip_provider.dart';
import 'package:smartcar/features/driver/data/driver_reservation_repository.dart';
import 'package:smartcar/features/driver/presentation/pages/driver_home_page.dart';
import 'package:smartcar/features/driver/presentation/pages/driver_reservation_requests_page.dart';

DriverReservationRequest request(String name) => DriverReservationRequest(
      id: name,
      passengerName: name,
      pickup: 'Gare',
      departureAt: DateTime(2027, 1, 8, 8, 15),
      seats: 1,
      contributionDh: 15,
      isUniversityVerified: true,
    );

Future<void> openRequests(
  WidgetTester tester,
  DemoDriverReservationRepository repository, {
  bool fromDashboard = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 620);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final page = DriverReservationRequestsPage(repository: repository);
  await tester.pumpWidget(ProviderScope(
    overrides: [tripRepositoryProvider.overrideWithValue(DemoTripRepository())],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: fromDashboard
          ? DriverHomePage(reservationRepository: repository)
          : page,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('right swipe accepts and left swipe requires confirmation',
      (tester) async {
    final repository =
        DemoDriverReservationRepository([request('Salma'), request('Omar')]);
    await openRequests(tester, repository);
    expect(find.text('2 à traiter'), findsOneWidget);

    await tester.drag(find.text('Salma'), const Offset(55, 0));
    await tester.pumpAndSettle();
    expect(repository.requests.first.status, DriverReservationStatus.pending);

    await tester.drag(find.text('Salma'), const Offset(145, 0));
    await tester.pumpAndSettle();
    expect(repository.requests.first.status, DriverReservationStatus.accepted);
    expect(find.text('1 à traiter'), findsOneWidget);

    await tester.drag(find.text('Omar'), const Offset(-145, 0));
    await tester.pumpAndSettle();
    expect(find.text('Refuser cette demande ?'), findsOneWidget);
    expect(repository.requests.last.status, DriverReservationStatus.pending);
    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Omar'), findsOneWidget);

    await tester.drag(find.text('Omar'), const Offset(-145, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer le refus'));
    await tester.pumpAndSettle();
    expect(repository.requests.last.status, DriverReservationStatus.rejected);
    expect(repository.requests, hasLength(2));
    expect(find.text('Aucune demande en attente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard opens requests and buttons share the decision flow',
      (tester) async {
    final repository =
        DemoDriverReservationRepository([request('Salma'), request('Omar')]);
    await openRequests(tester, repository, fromDashboard: true);
    await tester.tap(find.text('Demandes').last);
    await tester.pumpAndSettle();
    final details = find.text('Voir les détails');
    await tester.ensureVisible(details);
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(find.text('Prise en charge').last.hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer les détails'));
    await tester.pumpAndSettle();
    final accept = find.byTooltip('Accepter la demande');
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(repository.requests.first.status, DriverReservationStatus.accepted);

    await tester.ensureVisible(find.byTooltip('Refuser la demande'));
    await tester.tap(find.byTooltip('Refuser la demande'));
    await tester.pumpAndSettle();
    expect(repository.requests.last.status, DriverReservationStatus.pending);
    await tester.tap(find.text('Confirmer le refus'));
    await tester.pumpAndSettle();
    expect(await repository.listPending(), isEmpty);
    expect(find.byTooltip('Accepter la demande'), findsNothing);
  });

  test('repository rejects a second decision and keeps the accepted request',
      () async {
    final repository = DemoDriverReservationRepository([request('Salma')]);
    await repository.decide('Salma', DriverReservationStatus.accepted);
    await expectLater(
      repository.decide('Salma', DriverReservationStatus.rejected),
      throwsStateError,
    );
    expect(repository.requests.single.status, DriverReservationStatus.accepted);
    expect(await repository.listPending(), isEmpty);
  });
}
