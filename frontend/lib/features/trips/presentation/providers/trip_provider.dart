import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/trip_repository.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  throw StateError('A trip repository must be supplied by the host.');
});
