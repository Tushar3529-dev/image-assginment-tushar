import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/images/images_bloc.dart';
import '../core/app_motion.dart';
import '../core/app_theme.dart';
import '../router/app_routes.dart';

/// Animated splash. The native splash shows the same white tile centred on
/// green, so the first frame here matches it exactly; then the tile bounces
/// and rises, the name and tagline fade in, and a progress line fills while
/// the Images stream delivers its first snapshot.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Duration _animation = Duration(milliseconds: 1800);
  static const Duration _maxWaitForImages = Duration(seconds: 3);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashScreen._animation,
  );

  late final Animation<double> _tileScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 12),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.9,
        end: 1.08,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 18,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.08,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 12,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 58),
  ]).animate(_controller);

  late final Animation<double> _tileLift = _interval(
    0.25,
    0.55,
    Curves.easeOutCubic,
  );
  late final Animation<double> _title = _interval(
    0.30,
    0.60,
    Curves.easeOutCubic,
  );
  late final Animation<double> _tagline = _interval(
    0.40,
    0.70,
    Curves.easeOutCubic,
  );
  late final Animation<double> _progress = _interval(
    0.50,
    1.00,
    Curves.easeInOut,
  );

  bool _started = false;

  Animation<double> _interval(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = AppMotion.reduced(context);
    if (reduced) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
    _finish(
      reduced ? const Duration(milliseconds: 300) : SplashScreen._animation,
    );
  }

  /// Leaves once the animation has played AND the first Images snapshot has
  /// arrived (or after a short timeout, so a slow network never blocks launch).
  Future<void> _finish(Duration minimum) async {
    final images = context.read<ImagesBloc>();
    final firstSnapshot = images.state.status != ImagesStatus.loading
        ? Future<void>.value()
        : images.stream
              .firstWhere((s) => s.status != ImagesStatus.loading)
              .then<void>((_) {})
              .timeout(SplashScreen._maxWaitForImages, onTimeout: () {});
    await Future.wait([Future<void>.delayed(minimum), firstSnapshot]);
    if (mounted) context.go(AppRoutes.upload);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // SizedBox.expand: the Stack fills the screen, so "center" is the
            // true screen centre, the same spot the native splash used.
            return SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, -40 * _tileLift.value),
                    child: Transform.scale(
                      scale: _tileScale.value,
                      child: Image.asset(
                        'assets/branding/splash_tile.png',
                        width: 96,
                        height: 96,
                        semanticLabel: 'Image Upload',
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, 46 + 12 * (1 - _title.value)),
                    child: Opacity(
                      opacity: _title.value,
                      child: const Text(
                        'Image Upload',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, 76 + 10 * (1 - _tagline.value)),
                    child: Opacity(
                      opacity: _tagline.value,
                      child: const Text(
                        'Upload once, see it live',
                        style: TextStyle(
                          color: Color(0xFFDDF3DD),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, 116),
                    child: Opacity(
                      opacity: _title.value,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          width: 96,
                          height: 3,
                          child: LinearProgressIndicator(
                            value: _progress.value,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
