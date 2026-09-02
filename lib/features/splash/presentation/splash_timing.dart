/// Named durations for every timed piece of the splash screen, so each
/// knob can be found and adjusted in one place.
class SplashTiming {
  const SplashTiming._();

  /// Logo fade+slide-in duration. Must be <= [minDisplay].
  static const entrance = Duration(milliseconds: 700);

  /// Minimum time the splash stays up before hand-off is eligible (still
  /// gated on the data warm-up settling too — see [SplashScreen._warmUp]).
  static const minDisplay = Duration(milliseconds: 2600);

  /// Logo scale/opacity recede, played during hand-off.
  static const recede = Duration(milliseconds: 500);

  /// Cross-fade duration of the route transition into HomeScreen.
  static const routeFade = Duration(milliseconds: 400);

  /// One steam-stroke rise-and-fade loop, in AppMark.
  static const steamLoop = Duration(milliseconds: 2600);

  /// Delay before the second steam stroke starts its loop, so the two
  /// strokes drift out of phase.
  static const steamOffset = Duration(milliseconds: 500);

  /// One thumb sweep loop of the LoadingBar.
  static const loadingBarLoop = Duration(milliseconds: 1500);
}
