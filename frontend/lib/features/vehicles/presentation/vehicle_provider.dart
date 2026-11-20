import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/vehicle.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  throw StateError('A vehicle repository must be supplied by the host.');
});

final vehiclesProvider = AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(
    VehiclesNotifier.new);

class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() => ref.watch(vehicleRepositoryProvider).list();

  Future<Vehicle> save(VehicleInput input, {String? id}) async {
    final saved = await ref.read(vehicleRepositoryProvider).save(input, id: id);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData([
        for (final vehicle in current)
          if (vehicle.id == saved.id) saved else vehicle,
        if (!current.any((vehicle) => vehicle.id == saved.id)) saved,
      ]);
    }
    return saved;
  }

  Future<void> delete(String id) async {
    await ref.read(vehicleRepositoryProvider).delete(id);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.where((vehicle) => vehicle.id != id).toList());
    }
  }
}
