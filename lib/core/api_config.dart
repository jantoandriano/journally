import 'dart:io';

/// Base URL for journally-api.
///
/// - Android emulator can't reach the host machine via `localhost` — it
///   maps `10.0.2.2` to the host instead.
/// - A physical Android device on the same network needs the host
///   machine's actual LAN IP, which can't be detected automatically;
///   override this if testing on one.
class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}
