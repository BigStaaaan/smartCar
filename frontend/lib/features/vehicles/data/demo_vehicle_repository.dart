import '../domain/vehicle.dart';

/// In-memory fixtures for the standalone preview. Restarting resets changes.
class DemoVehicleRepository implements VehicleRepository {
  DemoVehicleRepository({Iterable<Vehicle> initialVehicles = samples})
      : _vehicles = {
          for (final vehicle in initialVehicles) vehicle.id: vehicle
        };

  static const samples = [
    Vehicle(
      id: 'dacia',
      details: (
        make: 'Dacia',
        model: 'Logan',
        color: 'Grise',
        year: null,
        registrationNumber: '12345 | A | 1',
        passengerCapacity: 4,
        photo: null,
        registrationPhoto: null,
      ),
    ),
  ];

  final Map<String, Vehicle> _vehicles;
  int _nextId = 0;

  @override
  Future<List<Vehicle>> list() async => List.unmodifiable(_vehicles.values);

  @override
  Future<Vehicle> save(VehicleInput details, {String? id}) async {
    if (id != null && !_vehicles.containsKey(id)) {
      throw StateError('Véhicule introuvable.');
    }
    String newId;
    do {
      newId = 'demo-${_nextId++}';
    } while (_vehicles.containsKey(newId) && id == null);
    final vehicle = Vehicle(id: id ?? newId, details: details);
    _vehicles[vehicle.id] = vehicle;
    return vehicle;
  }

  @override
  Future<void> delete(String id) async {
    if (_vehicles.remove(id) == null) throw StateError('Véhicule introuvable.');
  }
}
