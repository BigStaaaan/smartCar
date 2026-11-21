import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcar/features/trips/data/repositories/demo_trip_repository.dart';
import 'package:smartcar/features/trips/presentation/pages/publish_trip_page.dart';
import 'package:smartcar/features/trips/presentation/providers/trip_provider.dart';
import 'package:smartcar/features/vehicles/data/demo_vehicle_repository.dart';
import 'package:smartcar/features/vehicles/domain/vehicle.dart';
import 'package:smartcar/features/vehicles/presentation/vehicle_provider.dart';

const compact = Vehicle(
  id: 'compact',
  details: (
    make: 'Renault',
    model: 'Clio',
    color: 'Bleue',
    year: null,
    registrationNumber: '67890 | ب | 33',
    passengerCapacity: 2,
    photo: null,
    registrationPhoto: null,
  ),
);

Future<void> tap(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<DemoTripRepository> open(
    WidgetTester tester, List<Vehicle> vehicles) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 620);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final trips = DemoTripRepository();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      vehicleRepositoryProvider
          .overrideWithValue(DemoVehicleRepository(initialVehicles: vehicles)),
      tripRepositoryProvider.overrideWithValue(trips),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: const PublishTripPage(isPreview: true),
    ),
  ));
  await tester.pumpAndSettle();
  return trips;
}

void main() {
  testWidgets('validates, swaps locations and publishes with vehicle capacity',
      (tester) async {
    final repository =
        await open(tester, [...DemoVehicleRepository.samples, compact]);
    final publish = find.text('Publier le trajet');
    final origin = find.byKey(const ValueKey('Départ'));
    final destination = find.byKey(const ValueKey('Destination'));

    await tap(tester, publish);
    expect(find.text('Départ obligatoire'), findsOneWidget);
    expect(repository.publishedTrips, isEmpty);
    await tester.ensureVisible(origin);
    await tester.enterText(origin, 'Campus');
    await tester.enterText(destination, 'campus');
    await tap(tester, publish);
    expect(find.text('Choisissez une autre destination'), findsOneWidget);
    expect(repository.publishedTrips, isEmpty);

    await tester.ensureVisible(destination);
    await tester.enterText(destination, 'Gare');
    await tap(tester, find.byTooltip('Inverser les lieux'));
    expect(tester.widget<TextFormField>(origin).controller?.text, 'Gare');
    await tap(tester, find.byTooltip('Ajouter 15 minutes'));
    expect(find.text('08:15'), findsOneWidget);
    await tap(tester, find.byTooltip('Choisir une date'));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tap(tester, find.text('Annuler'));

    await tap(tester, find.text('Changer ⇄'));
    await tap(tester, find.text('Renault Clio'));
    expect(find.text('Jusqu’à 30 DH pour ce trajet'), findsOneWidget);
    final slider = find.byType(Slider);
    tester.widget<Slider>(slider).onChanged!(0);
    await tester.pumpAndSettle();
    expect(find.text('Gratuit'), findsOneWidget);
    await tap(tester, publish);

    final saved = repository.publishedTrips.single.details;
    expect(saved.origin, 'Gare');
    expect(saved.destination, 'Campus');
    expect(saved.vehicleId, 'compact');
    expect(saved.seats, 2);
    expect(saved.departureAt.hour, 8);
    expect(saved.departureAt.minute, 15);
    expect(saved.contributionDh, isNull);
    expect(find.text('Enregistré dans le Preview local'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects exact minutes, keeps the steps and revalidates the date',
      (tester) async {
    await open(tester, DemoVehicleRepository.samples);
    await tap(tester, find.text('08:00'));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tap(tester, find.byIcon(Icons.keyboard_outlined));
    final inputs = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(inputs.at(0), '14');
    await tester.enterText(inputs.at(1), '37');
    await tap(tester, find.text('Choisir'));
    expect(find.text('14:37'), findsOneWidget);

    await tap(tester, find.byTooltip('Ajouter 15 minutes'));
    expect(find.text('14:52'), findsOneWidget);
    await tap(tester, find.byTooltip('Retirer 15 minutes'));
    expect(find.text('14:37'), findsOneWidget);
    await tap(tester, find.text('14:37'));
    await tap(tester, find.text('Annuler'));
    expect(find.text('14:37'), findsOneWidget);

    await tap(tester, find.text('Auj.'));
    await tap(tester, find.text('14:37'));
    await tap(tester, find.byIcon(Icons.keyboard_outlined));
    await tester.enterText(inputs.at(0), '00');
    await tester.enterText(inputs.at(1), '00');
    await tap(tester, find.text('Choisir'));
    const invalid = 'Choisissez une date et une heure de départ futures.';
    expect(find.text(invalid), findsOneWidget);
    await tap(tester, find.text('Demain'));
    expect(find.text(invalid), findsNothing);
  });
  testWidgets('requires a vehicle and opens its management in the preview',
      (tester) async {
    final repository = await open(tester, []);
    await tester.enterText(find.byKey(const ValueKey('Départ')), 'Gare');
    await tester.enterText(find.byKey(const ValueKey('Destination')), 'Campus');
    await tap(tester, find.text('Publier le trajet'));
    expect(find.text('Sélectionnez un véhicule disposant de places.'),
        findsOneWidget);
    expect(repository.publishedTrips, isEmpty);
    await tap(tester, find.text('Ajouter'));
    expect(find.text('Mes véhicules'), findsOneWidget);
  });
}
