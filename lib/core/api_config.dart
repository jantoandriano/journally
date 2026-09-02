import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL for journally-api.
///
/// - Android emulator can't reach the host machine via `localhost` — it
///   maps `10.0.2.2` to the host instead.
/// - A physical Android device on the same network needs the host
///   machine's actual LAN IP, which can't be detected automatically;
///   override this if testing on one.
/// - `dart:io`'s `Platform` throws on web, so it must be checked only
///   after ruling out web via `kIsWeb`.
class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}
