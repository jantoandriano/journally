import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/domain/auth_state.dart';
import '../auth/presentation/providers/auth_providers.dart';
import 'api_client.dart';

part 'api_client_providers.g.dart';

@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  return buildApiClient(
    getAccessToken: () async {
      final state = ref.read(authControllerProvider);
      return state is AuthLoggedIn ? state.accessToken : null;
    },
    onRefresh: () => ref.read(authControllerProvider.notifier).refreshAccessToken(),
    onRefreshFailed: () => ref.read(authControllerProvider.notifier).forceLogout(),
  );
}
