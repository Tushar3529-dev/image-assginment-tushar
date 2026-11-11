import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../blocs/upload/upload_bloc.dart';
import '../core/app_motion.dart';
import '../screens/home_shell.dart';
import '../screens/images/image_viewer_screen.dart';
import '../screens/images/images_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/upload/pick_source_screen.dart';
import '../screens/upload/preview_screen.dart';
import 'app_routes.dart';

/// Turns a bloc's state stream into a [Listenable] so GoRouter re-runs
/// redirects whenever the state changes.
class BlocRefreshListenable extends ChangeNotifier {
  BlocRefreshListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Explicit [MaterialPage]s: go_router's MaterialApp auto-detection can fall
/// back to `NoTransitionPage`, which has no slide transition and no iOS
/// swipe-back gesture.
Page<void> _page(GoRouterState state, Widget child) =>
    MaterialPage<void>(key: state.pageKey, name: state.name, child: child);

/// The viewer zooms out of the tapped tile. The tile's on-screen rect arrives
/// as `extra`; without it (deep link) the zoom starts from the centre.
Page<void> _zoomPage(GoRouterState state, Widget child) {
  final origin = state.extra is Rect ? state.extra! as Rect : null;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    opaque: false,
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final size = MediaQuery.sizeOf(context);
      final alignment = origin == null || size.isEmpty
          ? Alignment.center
          : Alignment(
              origin.center.dx / size.width * 2 - 1,
              origin.center.dy / size.height * 2 - 1,
            );
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          alignment: alignment,
          scale: Tween(begin: 0.35, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Built after the blocs exist so the preview guard can read [UploadBloc].
GoRouter createRouter(
  UploadBloc uploadBloc, {
  String initialLocation = AppRoutes.splash,
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: BlocRefreshListenable(uploadBloc.stream),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        // Fades the whole app in over the splash.
        pageBuilder: (context, state, navigationShell) =>
            CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: AppMotion.slow,
              child: HomeShell(navigationShell: navigationShell),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) =>
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                        child: child,
                      ),
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.upload,
                name: AppRoutes.uploadName,
                pageBuilder: (context, state) =>
                    _page(state, const PickSourceScreen()),
                routes: [
                  GoRoute(
                    path: AppRoutes.uploadPreviewSegment,
                    name: AppRoutes.uploadPreviewName,
                    redirect: (context, state) =>
                        uploadBloc.state.pickedFile == null
                        ? AppRoutes.upload
                        : null,
                    pageBuilder: (context, state) =>
                        _page(state, const PreviewScreen()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.images,
                name: AppRoutes.imagesName,
                pageBuilder: (context, state) =>
                    _page(state, const ImagesScreen()),
                routes: [
                  GoRoute(
                    path: AppRoutes.imageViewerSegment,
                    name: AppRoutes.imageViewerName,
                    // Above the shell, so it covers the bottom bar.
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (context, state) => _zoomPage(
                      state,
                      ImageViewerScreen(imageId: state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
