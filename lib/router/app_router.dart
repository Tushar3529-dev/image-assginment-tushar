import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../blocs/upload/upload_bloc.dart';
import '../screens/home_shell.dart';
import '../screens/images/images_screen.dart';
import '../screens/not_found_screen.dart';
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

/// Built after the blocs exist so the preview guard can read [UploadBloc].
GoRouter createRouter(UploadBloc uploadBloc) {
  return GoRouter(
    initialLocation: AppRoutes.upload,
    refreshListenable: BlocRefreshListenable(uploadBloc.stream),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
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
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
