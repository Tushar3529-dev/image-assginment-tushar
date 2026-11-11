import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/images/images_bloc.dart';
import '../../core/app_motion.dart';
import '../../models/image_item.dart';
import '../../router/app_routes.dart';
import '../../widgets/app_snackbar.dart';

/// Full-screen view of one image: pinch or double-tap to zoom, swipe down to
/// close. If the document is deleted while it's open, the viewer closes.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key, required this.imageId});

  final String imageId;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with TickerProviderStateMixin {
  static const _dismissDistance = 140.0;
  static const _maxScale = 4.0;
  static const _doubleTapScale = 2.5;

  final _transform = TransformationController();
  late final AnimationController _zoomAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final AnimationController _snapBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _zoomTween;
  Animation<double>? _snapTween;
  Offset _doubleTapAt = Offset.zero;
  double _dragDy = 0;
  bool _zoomed = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _zoomAnim.addListener(() {
      if (_zoomTween != null) _transform.value = _zoomTween!.value;
    });
    _snapBack.addListener(() {
      if (_snapTween != null) setState(() => _dragDy = _snapTween!.value);
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    _zoomAnim.dispose();
    _snapBack.dispose();
    super.dispose();
  }

  ImageItem? _find(List<ImageItem> images) {
    for (final item in images) {
      if (item.id == widget.imageId) return item;
    }
    return null;
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.images);
    }
  }

  void _onDoubleTap() {
    final zoomedIn = _transform.value.getMaxScaleOnAxis() > 1.01;
    final Matrix4 target;
    if (zoomedIn) {
      target = Matrix4.identity();
    } else {
      final p = _doubleTapAt;
      target = Matrix4.identity()
        ..translateByDouble(
          -p.dx * (_doubleTapScale - 1),
          -p.dy * (_doubleTapScale - 1),
          0,
          1,
        )
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
    }
    setState(() => _zoomed = !zoomedIn);
    if (AppMotion.reduced(context)) {
      _transform.value = target;
      return;
    }
    _zoomTween = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).animate(CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic));
    _zoomAnim.forward(from: 0);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _dragDy = (_dragDy + details.delta.dy).clamp(-400.0, 600.0));
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragDy > _dismissDistance || velocity > 900) {
      _close();
      return;
    }
    _snapTween = Tween(
      begin: _dragDy,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _snapBack, curve: Curves.easeOutCubic));
    _snapBack.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final backdrop = (1 - _dragDy.abs() / 500).clamp(0.2, 1.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocConsumer<ImagesBloc, ImagesState>(
        listenWhen: (prev, curr) =>
            _find(prev.images) != null && _find(curr.images) == null,
        listener: (context, state) {
          showAppSnackBar(context, 'This image was deleted', isError: true);
          _close();
        },
        builder: (context, state) {
          final item = _find(state.images);
          return Scaffold(
            backgroundColor: Colors.black.withValues(alpha: backdrop),
            body: Stack(
              children: [
                if (item == null)
                  _Missing(loading: state.status == ImagesStatus.loading)
                else
                  GestureDetector(
                    onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
                    onDoubleTap: _onDoubleTap,
                    onVerticalDragUpdate: _zoomed ? null : _onDragUpdate,
                    onVerticalDragEnd: _zoomed ? null : _onDragEnd,
                    child: Transform.translate(
                      offset: Offset(0, _dragDy),
                      child: InteractiveViewer(
                        transformationController: _transform,
                        minScale: 1,
                        maxScale: _maxScale,
                        panEnabled: _zoomed,
                        onInteractionEnd: (_) => setState(
                          () => _zoomed =
                              _transform.value.getMaxScaleOnAxis() > 1.01,
                        ),
                        child: SizedBox.expand(
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (_, _, _) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                                size: 56,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Opacity(
                    opacity: backdrop,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Close',
                            onPressed: _close,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.15,
                              ),
                            ),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item?.referenceName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (item != null)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: SafeArea(child: _Hint()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "Pinch to zoom · swipe down to close", fading away after a moment.
class _Hint extends StatefulWidget {
  const _Hint();

  @override
  State<_Hint> createState() => _HintState();
}

class _HintState extends State<_Hint> {
  bool _visible = true;
  late final Timer _timer = Timer(const Duration(milliseconds: 2200), () {
    if (mounted) setState(() => _visible = false);
  });

  @override
  void initState() {
    super.initState();
    _timer; // start the countdown
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppMotion.of(context, AppMotion.slow),
      child: const Text(
        'Pinch to zoom · swipe down to close',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white54,
            size: 56,
          ),
          SizedBox(height: 12),
          Text(
            'This image was deleted',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
