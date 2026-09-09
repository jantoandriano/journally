import 'package:journally/core/network/api_client_providers.dart';
import 'package:journally/features/feeding_logs/data/http_feeding_logs_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/feeding_log_entry.dart';
import '../../domain/feeding_logs_repository.dart';

part 'feeding_logs_providers.g.dart';

@riverpod
FeedingLogsRepository feedingLogsRepository(Ref ref) {
  return HttpFeedingLogsRepository(dio: ref.watch(apiClientProvider));
}

@riverpod
Future<List<FeedingLogEntry>> feedingLog(Ref ref, String sightingId) {
  return ref.watch(feedingLogsRepositoryProvider).fetchFeedingLog(sightingId);
}
