import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcar/features/trips/data/repositories/demo_trip_repository.dart';
import 'package:smartcar/features/trips/domain/entities/publish_trip.dart';
import 'package:smartcar/features/trips/domain/entities/trip.dart';
import 'package:smartcar/features/trips/presentation/pages/my_trips_page.dart';
import 'package:smartcar/features/trips/presentation/pages/publish_trip_page.dart';
import 'package:smartcar/features/trips/presentation/providers/trip_provider.dart';
import 'package:smartcar/features/vehicles/data/demo_vehicle_repository.dart';
import 'package:smartcar/features/vehicles/presentation/vehicle_provider.dart';

Future<void> openTrips(
  WidgetTester tester,
  DemoTripRepository repository, {
  ({String? origin, String? destination}) Function(Trip trip)? coordinateLabels,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 620);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      tripRepositoryProvider.overrideWithValue(repository),
      vehicleRepositoryProvider.overrideWithValue(DemoVehicleRepository()),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: MyTripsPage(
        isPreview: true,
        coordinateLabels: coordinateLabels,
        onPublish: (context) => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => const PublishTripPage(isPreview: true),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Trip savedTrip(String origin, DateTime departure,
        {TripStatus status = TripStatus.published}) =>
    Trip(
      id: origin,
      status: status,
      details: PublishTrip(
        origin: origin,
        destination: 'Université',
        departureAt: departure,
        vehicleId: 'dacia',
        seats: 2,
      ),
    );

void main() {
  testWidgets('refreshes after publishing and shows the real trip on 320 px',
      (tester) async {
    final repository = DemoTripRepository();
    await openTrips(tester, repository);
    expect(find.text('Rien ici'), findsOneWidget);
    expect(await repository.listMine(), isEmpty);

    await tap(tester, find.text('Publier un trajet'));
    await tester.enterText(find.byKey(const ValueKey('Départ')), 'Gare');
    await tester.enterText(find.byKey(const ValueKey('Destination')), 'Campus');
    await tap(tester, find.text('Publier le trajet'));
    await tap(tester, find.text('Terminer'));

    expect(find.text('Mes trajets'), findsOneWidget);
    expect(find.text('1 à venir'), findsOneWidget);
    expect(find.text('Gare'), findsOneWidget);
    expect(find.text('Campus'), findsOneWidget);
    expect(find.text('Dacia Logan'), findsOneWidget);
    expect(find.text('3 places proposées'), findsOneWidget);
    expect(find.text('15 DH'), findsOneWidget);

    await tap(tester, find.text('Gare'));
    expect(find.text('Gare → Campus', findRichText: true), findsOneWidget);
    expect(find.text('Places proposées'), findsOneWidget);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Modifier'))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Annuler'))
            .onPressed,
        isNull);
    expect(find.text('12 km'), findsNothing);
    expect(find.text('25 min'), findsNothing);
    expect(tester.takeException(), isNull);
    await tap(tester, find.byTooltip('Retour aux trajets'));
    expect(find.text('Mes trajets'), findsOneWidget);
  });

  testWidgets('filters upcoming, past, and cancelled trips independently',
      (tester) async {
    final now = DateTime.now();
    final future = now.add(const Duration(days: 2));
    await openTrips(
        tester,
        DemoTripRepository(initialTrips: [
          savedTrip('Départ futur', future),
          savedTrip('Départ passé', now.subtract(const Duration(days: 2))),
          savedTrip('Départ annulé', future, status: TripStatus.cancelled),
        ]));

    expect(find.text('Départ futur'), findsOneWidget);
    expect(find.text('Départ annulé'), findsNothing);
    await tap(tester, find.text('Passés'));
    expect(find.text('Départ passé'), findsOneWidget);
    expect(find.text('Départ futur'), findsNothing);
    await tap(tester, find.text('Annulés'));
    expect(find.text('Départ annulé'), findsOneWidget);
    expect(find.text('Départ passé'), findsNothing);
    await tap(tester, find.text('Départ annulé'));
    expect(find.text('Annulé'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);
  });

  testWidgets('shows the exact coordinate labels supplied by the preview',
      (tester) async {
    final trip = savedTrip('Gare', DateTime.now().add(const Duration(days: 2)));
    await openTrips(
      tester,
      DemoTripRepository(initialTrips: [trip]),
      coordinateLabels: (selected) {
        expect(identical(selected, trip), isTrue);
        return (origin: '31.630000, -8.000000', destination: null);
      },
    );
    await tap(tester, find.text('Gare'));
    expect(find.text('Départ · 31.630000, -8.000000'), findsOneWidget);
    expect(find.textContaining('Destination ·'), findsNothing);
  });
}
