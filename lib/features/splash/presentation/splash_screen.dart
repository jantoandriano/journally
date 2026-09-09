import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journally/core/auth/domain/auth_state.dart';
import 'package:journally/core/auth/presentation/providers/auth_providers.dart';
import 'package:journally/core/location_provider.dart';
import 'package:journally/features/auth/presentation/login_screen.dart';
import 'package:journally/features/home/presentation/home_screen.dart';
import 'package:journally/features/cafes/presentation/providers/cafe_providers.dart';
import 'package:journally/features/sightings/presentation/providers/sightings_providers.dart';

import 'splash_timing.dart';
import 'widgets/ambient_shapes.dart';
import 'widgets/app_mark.dart';
import 'widgets/loading_bar.dart';
import 'widgets/wordmark.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _motif;
  late final Animation<double> _entrance;
  bool _receding = false;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: SplashTiming.entry);
    _motif = AnimationController(vsync: this, duration: SplashTiming.motif);
    _entrance = CurvedAnimation(
      parent: _entry,
      curve: Interval(
        0,
        SplashTiming.entranceIn.inMilliseconds /
            SplashTiming.entry.inMilliseconds,
        curve: Curves.easeOut,
      ),
    );

    final animFuture = _entry.forward();
    _motif.repeat();
    final dataFuture = _warmUp();
    Future.wait([animFuture, dataFuture]).then((_) => _handOff());
  }

  Future<void> _warmUp() async {
    await _waitForAuthResolved();

    if (ref.read(authControllerProvider) is AuthLoggedIn) {
      await Future.wait([
        _settle(ref.read(cafeEntriesProvider.future)),
        _settle(ref.read(sightingsProvider.future)),
        _settle(ref.read(deviceLocationProvider.future)),
      ]);
    }
  }

  Future<void> _waitForAuthResolved() async {
    if (ref.read(authControllerProvider) is! AuthLoading) return;

    final completer = Completer<void>();
    late final ProviderSubscription<AuthState> subscription;
    subscription = ref.listenManual(authControllerProvider, (previous, next) {
      if (next is! AuthLoading) {
        subscription.close();
        completer.complete();
      }
    });
    await completer.future;
  }

  Future<void> _settle(Future<void> future) async {
    try {
      await future;
    } catch (_) {
      // Settled, not necessarily successful — home renders its own error state.
    }
  }

  void _handOff() {
    if (!mounted) return;
    setState(() => _receding = true);

    final isLoggedIn = ref.read(authControllerProvider) is AuthLoggedIn;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: SplashTiming.routeFade,
        pageBuilder: (context, animation, secondaryAnimation) =>
            isLoggedIn ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    _motif.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sightingsAsync = ref.watch(sightingsProvider);
    final status = sightingsAsync.when(
      data: (sightings) => 'Jakarta · ${sightings.length} sightings',
      loading: () => 'Jakarta',
      error: (_, _) => 'Jakarta',
    );

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: Stack(
        children: [
          const AmbientShapes(),
          Center(
            child: AnimatedBuilder(
              animation: _entrance,
              builder: (context, child) {
                return Opacity(
                  opacity: _entrance.value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - _entrance.value)),
                    child: child,
                  ),
                );
              },
              child: AnimatedScale(
                scale: _receding ? 0.72 : 1.0,
                duration: SplashTiming.recede,
                curve: Curves.easeIn,
                child: AnimatedOpacity(
                  opacity: _receding ? 0.42 : 1.0,
                  duration: SplashTiming.recede,
                  curve: Curves.easeIn,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppMark(motif: _motif),
                      const SizedBox(height: 24),
                      const Wordmark(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoadingBar(),
                const SizedBox(height: 16),
                Text(
                  status,
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
