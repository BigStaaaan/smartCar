import 'dart:typed_data';

typedef VehicleInput = ({
  String make,
  String model,
  String color,
  int? year,
  String registrationNumber,
  int passengerCapacity,
  Uint8List? photo,
  Uint8List? registrationPhoto,
});

class Vehicle {
  const Vehicle({required this.id, required this.details});

  final String id;
  final VehicleInput details;

  String get name => '${details.make} ${details.model}';
}

abstract interface class VehicleRepository {
  Future<List<Vehicle>> list();
  Future<Vehicle> save(VehicleInput details, {String? id});
  Future<void> delete(String id);
}
