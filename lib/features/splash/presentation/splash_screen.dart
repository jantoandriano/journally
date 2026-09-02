import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journally/features/home/presentation/home_screen.dart';
import 'package:journally/features/home/presentation/providers/home_providers.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _entrance;
  bool _receding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SplashTiming.minDisplay,
    );
    _entrance = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0,
        SplashTiming.entrance.inMilliseconds /
            SplashTiming.minDisplay.inMilliseconds,
        curve: Curves.easeOut,
      ),
    );

    final animFuture = _controller.forward();
    final dataFuture = _warmUp();
    Future.wait([animFuture, dataFuture]).then((_) => _handOff());
  }

  Future<void> _warmUp() async {
    try {
      await ref.read(journalEntriesProvider.future);
    } catch (_) {
      // Settled, not necessarily successful — home renders its own error state.
    }
  }

  void _handOff() {
    if (!mounted) return;
    setState(() => _receding = true);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: SplashTiming.routeFade,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final entriesAsync = ref.watch(journalEntriesProvider);
    final status = entriesAsync.when(
      data: (entries) => 'Jakarta · ${entries.length} places',
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
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [AppMark(), SizedBox(height: 24), Wordmark()],
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
