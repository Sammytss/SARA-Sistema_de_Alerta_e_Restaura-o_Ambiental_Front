import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/result.dart';
import '../../core/providers/app_providers.dart';
import '../../data/datasources/remote/satellite_remote_datasource.dart';
import '../../data/models/satellite_frame.dart';

final satelliteDatasourceProvider = Provider<SatelliteRemoteDatasource>((ref) {
  if (AppConfig.useMockData) return SatelliteRemoteMock();
  return SatelliteRemoteReal(ref.read(apiClientProvider));
});

final satelliteTimelineProvider =
    FutureProvider.family<SatelliteTimeline, String>((ref, areaId) async {
  final datasource = ref.watch(satelliteDatasourceProvider);
  final result = await datasource.getTimeline(areaId: areaId);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw error,
  };
});
