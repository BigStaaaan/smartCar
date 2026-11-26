import '../../domain/entities/map_location.dart';
import '../../domain/repositories/maps_repository.dart';
import '../datasources/maps_remote_datasource.dart';

class MapsRepositoryImpl implements MapsRepository {
  const MapsRepositoryImpl(this._dataSource);

  final MapsRemoteDataSource _dataSource;

  @override
  Future<MapLocation> getCurrentLocation() => _dataSource.getCurrentLocation();
}
