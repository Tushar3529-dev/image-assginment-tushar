import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'blocs/images/images_bloc.dart';
import 'blocs/upload/upload_bloc.dart';
import 'core/app_scroll_behavior.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'repositories/image_repository.dart';
import 'router/app_router.dart';
import 'services/cloudinary_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final cloudinaryService = CloudinaryService();
  final imageRepository = ImageRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: cloudinaryService),
        RepositoryProvider.value(value: imageRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => UploadBloc(
              cloudinaryService: cloudinaryService,
              imageRepository: imageRepository,
            ),
          ),
          // Created once, above the router: the Firestore listener lives for
          // the whole app session.
          BlocProvider(
            lazy: false,
            create: (_) =>
                ImagesBloc(imageRepository)
                  ..add(const ImagesSubscriptionRequested()),
          ),
        ],
        child: const ImageApp(),
      ),
    ),
  );
}

class ImageApp extends StatefulWidget {
  const ImageApp({super.key});

  @override
  State<ImageApp> createState() => _ImageAppState();
}

class _ImageAppState extends State<ImageApp> {
  late final GoRouter _router = createRouter(context.read<UploadBloc>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Image Upload',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: _router,
    );
  }
}
