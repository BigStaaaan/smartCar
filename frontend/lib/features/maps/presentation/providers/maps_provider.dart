import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/maps_remote_datasource.dart';
import '../../data/repositories/maps_repository_impl.dart';
import '../../domain/entities/map_location.dart';
import '../../domain/usecases/get_trip_locations.dart';

final mapsDataSourceProvider = Provider<MapsRemoteDataSource>(
  (ref) => MapsRemoteDataSource(),
);

final mapsRepositoryProvider = Provider<MapsRepositoryImpl>(
  (ref) => MapsRepositoryImpl(ref.watch(mapsDataSourceProvider)),
);

final getCurrentLocationProvider = Provider<GetCurrentLocation>(
  (ref) => GetCurrentLocation(ref.watch(mapsRepositoryProvider)),
);

final currentLocationProvider = FutureProvider<MapLocation>(
  (ref) => ref.watch(getCurrentLocationProvider).call(),
);
