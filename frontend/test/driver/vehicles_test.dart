import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartcar/features/vehicles/data/demo_vehicle_repository.dart';
import 'package:smartcar/features/vehicles/domain/vehicle.dart';
import 'package:smartcar/features/vehicles/presentation/vehicle_images.dart';
import 'package:smartcar/features/vehicles/presentation/vehicle_provider.dart';
import 'package:smartcar/features/vehicles/presentation/vehicles_page.dart';

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  Future<void> open(WidgetTester tester, VehicleRepository repository) =>
      tester.pumpWidget(ProviderScope(
        overrides: [vehicleRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: VehiclesPage(isDemo: true)),
      ));

  testWidgets('validates the Moroccan plate and saves and edits manual data',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 620);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = DemoVehicleRepository(initialVehicles: []);
    await open(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('Aucun véhicule'), findsOneWidget);
    await tap(tester, find.text('Ajouter un véhicule'));
    final submit = find.text('Ajouter le véhicule');
    await tap(tester, submit);
    expect(find.text('Complétez le numéro, la lettre et le code province.'),
        findsOneWidget);
    expect(await repository.list(), isEmpty);

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
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tap(tester, submit);
    expect(find.text('Véhicule enregistré'), findsOneWidget);
    expect((await repository.list()).single.details.registrationNumber,
        '12345 | ب | 33');
    expect((await repository.list()).single.details.year, 2021);
    await tap(tester, find.text('Terminer'));
    await tap(tester, find.text('Renault Clio'));
    expect(find.text('4 places'), findsOneWidget);
    await tap(tester, find.text('Modifier'));
    await tester.enterText(find.byType(TextFormField).at(1), 'Captur');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tap(tester, find.text('Enregistrer'));
    await tap(tester, find.text('Terminer'));
    expect(find.text('Renault Captur'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Renault Captur'), findsOneWidget);
  });

  testWidgets('picks and replaces images without changing the vehicle fields',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final car = base64Decode(_pixel);
    final registration = base64Decode(_pixel);
    final replacement = base64Decode(_pixel);
    final images = [registration, replacement, car].iterator;
    final sources = <ImageSource>[];
    final scan = Completer<void>();
    final repository = DemoVehicleRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(repository),
        vehicleImagePickerProvider.overrideWithValue(
          (source, {required maxDimension}) async {
            sources.add(source);
            if (sources.length == 1) await scan.future;
            return images.moveNext() ? images.current : null;
          },
        ),
      ],
      child: const MaterialApp(home: VehiclesPage(isDemo: true)),
    ));
    await tester.pumpAndSettle();

    await tap(tester, find.text('Dacia Logan'));
    await tap(tester, find.text('Modifier'));
    final scanner = find.text('Scanner');
    final gallery = find.text('Remplacer depuis la galerie');
    expect(tester.getTopLeft(scanner).dy,
        lessThan(tester.getTopLeft(find.text('Marque *')).dy));
    await tester.tap(scanner);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Préparation de l’image…'), findsOneWidget);
    scan.complete();
    await tester.pumpAndSettle();
    expect(find.text('Rescanner'), findsOneWidget);
    await tap(tester, gallery);
    await tap(tester, find.text('Prendre une photo'));
    await tap(tester, find.text('Enregistrer'));
    await tap(tester, find.text('Terminer'));

    expect(
        sources, [ImageSource.camera, ImageSource.gallery, ImageSource.camera]);
    final saved = (await repository.list()).single.details;
    expect(saved.make, 'Dacia');
    expect(saved.model, 'Logan');
    expect(saved.registrationNumber, '12345 | A | 1');
    expect(saved.year, isNull);
    expect(saved.photo, same(car));
    expect(saved.registrationPhoto, same(replacement));
    final enlarged = find.bySemanticsLabel('Agrandir : Carte grise');
    await tap(tester, enlarged);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tap(tester, find.byTooltip('Fermer l’aperçu'));

    await tap(tester, find.text('Modifier'));
    await tap(tester, find.byTooltip('Retirer : Carte grise'));
    await tap(tester, find.text('Enregistrer'));
    await tap(tester, find.text('Terminer'));
    expect((await repository.list()).single.details.registrationPhoto, isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Photo du véhicule'), findsOneWidget);
  });

  testWidgets('deletes only after confirmation', (tester) async {
    await open(tester, DemoVehicleRepository());
    await tester.pumpAndSettle();
    await tap(tester, find.text('Dacia Logan'));
    await tap(tester, find.text('Supprimer'));
    await tap(tester, find.text('Annuler'));
    expect(find.text('Dacia Logan'), findsOneWidget);
    await tap(tester, find.text('Supprimer'));
    await tap(tester, find.text('Confirmer la suppression'));
    expect(find.text('Aucun véhicule'), findsOneWidget);
  });

  testWidgets('shows loading, then error, and can retry', (tester) async {
    final repository = _RetryRepository();
    await open(tester, repository);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.firstRequest.completeError(StateError('Demo failure'));
    await tester.pumpAndSettle();
    expect(find.text('Impossible de charger vos véhicules'), findsOneWidget);
    await tap(tester, find.text('Réessayer'));
    expect(find.text('Dacia Logan'), findsOneWidget);
  });
}

class _RetryRepository extends DemoVehicleRepository {
  final firstRequest = Completer<List<Vehicle>>();
  bool _first = true;

  @override
  Future<List<Vehicle>> list() {
    if (!_first) return super.list();
    _first = false;
    return firstRequest.future;
  }
}

const _pixel =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
