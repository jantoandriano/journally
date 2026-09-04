/// Named durations for every timed piece of the splash screen, so each
/// knob can be found and adjusted in one place.
class SplashTiming {
  const SplashTiming._();

  /// Total lifetime of the entry controller — forward once, not repeating.
  static const entry = Duration(milliseconds: 1600);

  /// Fade+slide-in portion of [entry], as a fraction of its total duration.
  static const entranceIn = Duration(milliseconds: 700);

  /// One full coffee-cup <-> paw-print cross-fade cycle in AppMark.
  static const motif = Duration(milliseconds: 4400);

  /// One pulse-ring expand+fade loop, in AppMark.
  static const pulseLoop = Duration(milliseconds: 2400);

  /// Delay before the second pulse ring starts its loop, so the two rings
  /// drift out of phase.
  static const pulseOffset = Duration(milliseconds: 800);

  /// One thumb sweep loop of the LoadingBar.
  static const loadingBarLoop = Duration(milliseconds: 1500);

  /// Logo scale/opacity recede, played during hand-off.
  static const recede = Duration(milliseconds: 400);

  /// Cross-fade duration of the route transition into HomeScreen.
  static const routeFade = Duration(milliseconds: 400);
}
