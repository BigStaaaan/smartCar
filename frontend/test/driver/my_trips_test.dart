import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcar/features/driver/presentation/pages/driver_home_page.dart';
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
  bool fromDashboard = false,
  DemoVehicleRepository? vehicles,
  ({String? origin, String? destination}) Function(Trip trip)? coordinateLabels,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 620);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      tripRepositoryProvider.overrideWithValue(repository),
      vehicleRepositoryProvider
          .overrideWithValue(vehicles ?? DemoVehicleRepository()),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: fromDashboard
          ? const DriverHomePage(isPreview: true)
          : MyTripsPage(
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
        {TripStatus status = TripStatus.published,
        List<String>? confirmedPassengerNames}) =>
    Trip(
      id: origin,
      status: status,
      confirmedPassengerNames: confirmedPassengerNames,
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
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Annuler le trajet'), findsOneWidget);
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

  testWidgets('prefills a trip and refreshes its detail and list after editing',
      (tester) async {
    final initial =
        savedTrip('Gare', DateTime.now().add(const Duration(days: 2)));
    final repository = DemoTripRepository(initialTrips: [initial]);
    await openTrips(tester, repository);
    await tap(tester, find.text('Gare'));
    await tap(tester, find.text('Modifier'));

    final originField = find.byKey(const ValueKey('Départ'));
    final destinationField = find.byKey(const ValueKey('Destination'));
    expect(tester.widget<TextFormField>(originField).controller!.text, 'Gare');
    expect(tester.widget<TextFormField>(destinationField).controller!.text,
        'Université');
    expect(find.text('Gratuit'), findsOneWidget);

    await tester.enterText(originField, '');
    await tap(tester, find.text('Enregistrer les modifications'));
    expect((await repository.listMine()).single.details.origin, 'Gare');

    await tap(tester, originField);
    await tester.enterText(originField, 'Bibliothèque');
    await tap(tester, find.text('Enregistrer les modifications'));

    final updated = (await repository.listMine()).single;
    expect(updated.id, initial.id);
    expect(updated.details.origin, 'Bibliothèque');
    expect(updated.details.seats, initial.details.seats);
    expect(updated.details.vehicleId, initial.details.vehicleId);
    expect(find.text('Bibliothèque → Université', findRichText: true),
        findsOneWidget);
    await tap(tester, find.byTooltip('Retour aux trajets'));
    expect(find.text('Bibliothèque'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a trip until cancellation is confirmed and moves it',
      (tester) async {
    final initial =
        savedTrip('Gare', DateTime.now().add(const Duration(days: 2)));
    final repository = DemoTripRepository(initialTrips: [initial]);
    await openTrips(tester, repository);
    await tap(tester, find.text('Gare'));
    await tap(tester, find.text('Annuler le trajet'));
    await tap(tester, find.text('Conserver le trajet'));
    expect((await repository.listMine()).single.status, TripStatus.published);

    await tap(tester, find.text('Annuler le trajet'));
    await tap(tester, find.text('Confirmer l’annulation'));
    final cancelled = (await repository.listMine()).single;
    expect(cancelled.status, TripStatus.cancelled);
    expect(cancelled.id, initial.id);
    expect(cancelled.details, same(initial.details));
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Annulé'), findsOneWidget);

    await tap(tester, find.byTooltip('Retour aux trajets'));
    expect(find.text('Gare'), findsNothing);
    await tap(tester, find.text('Annulés'));
    expect(find.text('Gare'), findsOneWidget);
  });

  test('repository rejects changes to past and cancelled trips', () async {
    final now = DateTime.now();
    final past = savedTrip('Passé', now.subtract(const Duration(days: 1)));
    final upcoming = savedTrip('À venir', now.add(const Duration(days: 1)));
    final repository = DemoTripRepository(initialTrips: [past, upcoming]);

    await expectLater(
        repository.update(past.id, upcoming.details), throwsStateError);
    await expectLater(repository.cancel(past.id), throwsStateError);
    await expectLater(
        repository.update(upcoming.id, past.details), throwsArgumentError);
    await repository.cancel(upcoming.id);
    await expectLater(
        repository.update(upcoming.id, upcoming.details), throwsStateError);
    await expectLater(repository.cancel(upcoming.id), throwsStateError);
  });

  testWidgets('confirms start and completion and refreshes the trip history',
      (tester) async {
    final ready =
        savedTrip('Gare', DateTime.now().subtract(const Duration(minutes: 5)));
    final repository = DemoTripRepository(initialTrips: [ready]);
    await openTrips(tester, repository);

    await tap(tester, find.text('Passés'));
    await tap(tester, find.text('Gare'));
    await tap(tester, find.text('Démarrer le trajet'));
    await tap(tester, find.text('Retour'));
    expect((await repository.listMine()).single.status, TripStatus.published);

    await tap(tester, find.text('Démarrer le trajet'));
    await tap(tester, find.text('Confirmer le démarrage'));
    expect((await repository.listMine()).single.status, TripStatus.inProgress);
    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('Trajet en cours'), findsOneWidget);
    expect(find.text('Liste des passagers indisponible'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Annuler le trajet'), findsNothing);

    await tap(tester, find.byTooltip('Retour aux trajets'));
    expect(find.text('Gare'), findsNothing);
    await tap(tester, find.text('À venir'));
    await tap(tester, find.text('Gare'));
    await tap(tester, find.text('Terminer le trajet'));
    await tap(tester, find.text('Retour'));
    expect((await repository.listMine()).single.status, TripStatus.inProgress);

    await tap(tester, find.text('Terminer le trajet'));
    await tap(tester, find.text('Confirmer la fin du trajet'));
    final completed = (await repository.listMine()).single;
    expect(completed.status, TripStatus.completed);
    expect(completed.details, same(ready.details));
    expect(find.text('Terminé'), findsOneWidget);
    expect(find.text('Démarrer le trajet'), findsNothing);
    expect(find.text('Terminer le trajet'), findsNothing);

    await tap(tester, find.byTooltip('Retour aux trajets'));
    expect(find.text('Gare'), findsNothing);
    await tap(tester, find.text('Passés'));
    expect(find.text('Gare'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);
  });

  test(
      'repository only starts due published trips and only completes active trips',
      () async {
    final now = DateTime.now();
    final due = now.subtract(const Duration(minutes: 5));
    final ready = savedTrip('Gare', due);
    final future = savedTrip('Futur', now.add(const Duration(days: 1)));
    final cancelled = savedTrip('Annulé', due, status: TripStatus.cancelled);
    final repository =
        DemoTripRepository(initialTrips: [ready, future, cancelled]);

    await expectLater(repository.start(future.id), throwsStateError);
    await expectLater(repository.start(cancelled.id), throwsStateError);
    await expectLater(repository.complete(ready.id), throwsStateError);
    await expectLater(repository.complete(cancelled.id), throwsStateError);
    expect((await repository.start(ready.id)).status, TripStatus.inProgress);
    await expectLater(repository.start(ready.id), throwsStateError);
    await expectLater(repository.cancel(ready.id), throwsStateError);
    await expectLater(
        repository.update(ready.id, future.details), throwsStateError);
    expect((await repository.complete(ready.id)).status, TripStatus.completed);
    await expectLater(repository.start(ready.id), throwsStateError);
    await expectLater(repository.complete(ready.id), throwsStateError);
  });

  testWidgets(
      'dashboard shares the vehicle and trip repositories across routes',
      (tester) async {
    final vehicles = DemoVehicleRepository(initialVehicles: []);
    final trips = DemoTripRepository();
    await openTrips(tester, trips, fromDashboard: true, vehicles: vehicles);

    expect(find.text('Demandes'), findsNothing);
    await tap(tester, find.text('Véhicules'));
    expect(find.text('Aucun véhicule'), findsOneWidget);
    await tap(tester, find.text('Ajouter un véhicule'));
    for (final (index, value) in ['Renault', 'Clio', '2021', 'Bleue'].indexed) {
      final field = find.byType(TextFormField).at(index);
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byKey(const ValueKey('Numéro')), '12345');
    await tap(tester, find.byKey(const ValueKey('plate-letter')));
    await tap(tester, find.text('ب').last);
    await tester.enterText(find.byKey(const ValueKey('Code province')), '33');
    await tap(tester, find.text('Ajouter le véhicule'));
    await tap(tester, find.text('Terminer'));
    await tap(tester, find.text('Renault Clio'));
    await tap(tester, find.text('Modifier'));
    await tester.enterText(find.byType(TextFormField).at(1), 'Captur');
    await tap(tester, find.text('Enregistrer'));
    await tap(tester, find.text('Terminer'));
    expect(find.text('Renault Captur'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tap(tester, find.byTooltip('Publier un trajet'));
    await tester.enterText(find.byKey(const ValueKey('Départ')), 'Gare');
    await tester.enterText(find.byKey(const ValueKey('Destination')), 'Campus');
    await tap(tester, find.text('Publier le trajet'));
    await tap(tester, find.text('Terminer'));
    expect(find.text('Mode Driver'), findsOneWidget);
    expect((await trips.listMine()).single.details.vehicleId,
        (await vehicles.list()).single.id);

    await tap(tester, find.text('Trajets'));
    await tap(tester, find.text('Gare'));
    expect(find.text('Renault Captur'), findsOneWidget);
    await tap(tester, find.text('Modifier'));
    await tester.enterText(
        find.byKey(const ValueKey('Destination')), 'Faculté');
    await tap(tester, find.text('Enregistrer les modifications'));
    expect(find.text('Gare → Faculté', findRichText: true), findsOneWidget);
    await tap(tester, find.text('Annuler le trajet'));
    await tap(tester, find.text('Confirmer l’annulation'));
    await tap(tester, find.byTooltip('Retour aux trajets'));
    await tap(tester, find.text('Annulés'));
    expect(find.text('Faculté'), findsOneWidget);
    await tap(tester, find.byTooltip('Retour'));
    expect(find.text('Mode Driver'), findsOneWidget);

    await tap(tester, find.text('Véhicules'));
    await tap(tester, find.text('Renault Captur'));
    await tap(tester, find.text('Supprimer'));
    await tap(tester, find.text('Confirmer la suppression'));
    expect(find.text('Aucun véhicule'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Mode Driver'), findsOneWidget);
  });

  testWidgets('dashboard reflects start and completion of its featured trip',
      (tester) async {
    final ready = savedTrip(
        'Départ de démo', DateTime.now().subtract(const Duration(minutes: 1)),
        confirmedPassengerNames: const ['Salma E.', 'Omar B.']);
    final repository = DemoTripRepository(initialTrips: [ready]);
    await openTrips(tester, repository, fromDashboard: true);

    expect(find.text('Prêt au départ'), findsOneWidget);
    await tap(tester, find.text('Voir le trajet'));
    await tap(tester, find.text('Démarrer le trajet'));
    await tap(tester, find.text('Confirmer le démarrage'));
    expect(find.text('Trajet en cours'), findsOneWidget);
    expect(find.text('Départ de démo'), findsOneWidget);
    expect(find.text('Université'), findsOneWidget);
    expect(find.text('Dacia Logan'), findsOneWidget);
    expect(find.text('Date et heure prévues'), findsOneWidget);
    expect(find.text('Salma E.'), findsOneWidget);
    expect(find.text('Omar B.'), findsOneWidget);
    expect(find.text('Schéma du trajet'), findsNothing);
    await tap(tester, find.byTooltip('Retour au Dashboard'));
    expect(find.text('En cours'), findsWidgets);
    expect(find.text('1'), findsOneWidget);

    await tap(tester, find.text('Voir le trajet'));
    expect(find.text('Trajet en cours'), findsOneWidget);
    expect(find.text('Démarrer le trajet'), findsNothing);
    expect(find.text('Salma E.'), findsOneWidget);
    await tap(tester, find.text('Terminer le trajet'));
    await tap(tester, find.text('Confirmer la fin du trajet'));
    await tap(tester, find.byTooltip('Retour au Dashboard'));
    expect(find.text('Aucun trajet prêt, à venir ou en cours'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Terminés'), findsOneWidget);

    await tap(tester, find.text('Trajets'));
    await tap(tester, find.text('Passés'));
    expect(find.text('Départ de démo'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);
    await tap(tester, find.byTooltip('Retour'));
    expect(find.text('Mode Driver'), findsOneWidget);
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
