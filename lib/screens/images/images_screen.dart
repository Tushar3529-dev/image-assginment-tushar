import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/images/images_bloc.dart';
import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../models/image_item.dart';
import '../../router/app_routes.dart';
import '../../widgets/skeleton_box.dart';

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  childAspectRatio: 0.82,
);

class ImagesScreen extends StatelessWidget {
  const ImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ImagesBloc, ImagesState>(
        builder: (context, state) {
          final Widget body = switch (state.status) {
            ImagesStatus.loading => const _SkeletonGrid(
              key: ValueKey('loading'),
            ),
            ImagesStatus.failure => _ErrorView(
              key: const ValueKey('failure'),
              message: state.errorMessage,
            ),
            ImagesStatus.loaded => LiveImageGrid(
              key: const ValueKey('loaded'),
              images: state.images,
            ),
          };
          return AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            child: body,
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Text(
            'Images',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
          if (count != null)
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.medium),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Container(
                key: ValueKey(count),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Grid that mirrors the Firestore list and animates the difference:
/// new documents pop in (and glow for a moment), deleted ones fade out.
class LiveImageGrid extends StatefulWidget {
  const LiveImageGrid({super.key, required this.images});

  final List<ImageItem> images;

  @override
  State<LiveImageGrid> createState() => _LiveImageGridState();
}

class _LiveImageGridState extends State<LiveImageGrid> {
  static const _freshFor = Duration(milliseconds: 2600);

  final _gridKey = GlobalKey<SliverAnimatedGridState>();
  late final List<ImageItem> _items = [...widget.images];
  final Map<String, Timer> _fresh = {};

  @override
  void didUpdateWidget(LiveImageGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.images, widget.images)) _sync(widget.images);
  }

  void _sync(List<ImageItem> next) {
    final grid = _gridKey.currentState;
    final insertDuration = AppMotion.of(context, AppMotion.slow);
    final removeDuration = AppMotion.of(context, AppMotion.medium);
    final nextIds = {for (final item in next) item.id};

    // 1. Removals, from the end so indices stay valid.
    for (var i = _items.length - 1; i >= 0; i--) {
      if (nextIds.contains(_items[i].id)) continue;
      final removed = _items.removeAt(i);
      _fresh.remove(removed.id)?.cancel();
      grid?.removeItem(
        i,
        (context, animation) =>
            _animatedTile(removed, animation, removing: true),
        duration: removeDuration,
      );
    }

    // 2. Insertions, moves and in-place updates, in the new order.
    for (var i = 0; i < next.length; i++) {
      final item = next[i];
      if (i < _items.length && _items[i].id == item.id) {
        _items[i] = item;
        continue;
      }
      final existing = _items.indexWhere((e) => e.id == item.id);
      if (existing != -1) {
        // Re-ordered (e.g. a server timestamp landed): move without animating.
        _items.removeAt(existing);
        grid?.removeItem(
          existing,
          (_, _) => const SizedBox.shrink(),
          duration: Duration.zero,
        );
        _items.insert(i, item);
        grid?.insertItem(i, duration: Duration.zero);
        continue;
      }
      _items.insert(i, item);
      grid?.insertItem(i, duration: insertDuration);
      _fresh[item.id] = Timer(_freshFor, () {
        if (!mounted) return;
        setState(() => _fresh.remove(item.id));
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final timer in _fresh.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Widget _animatedTile(
    ImageItem item,
    Animation<double> animation, {
    bool removing = false,
  }) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: removing ? Curves.easeIn : Curves.easeOutBack,
    );
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: removing ? 0.8 : 0.5, end: 1.0).animate(curved),
        child: IgnorePointer(
          ignoring: removing,
          child: ImageTile(
            key: ValueKey(item.id),
            item: item,
            fresh: _fresh.containsKey(item.id),
            onTap: (rect) =>
                context.go(AppRoutes.imageViewer(item.id), extra: rect),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          key: const PageStorageKey('images-grid'),
          slivers: [
            SliverToBoxAdapter(child: _Header(count: _items.length)),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverAnimatedGrid(
                key: _gridKey,
                initialItemCount: _items.length,
                gridDelegate: _gridDelegate,
                itemBuilder: (context, index, animation) =>
                    _animatedTile(_items[index], animation),
              ),
            ),
          ],
        ),
        IgnorePointer(
          ignoring: _items.isNotEmpty,
          child: AnimatedOpacity(
            opacity: _items.isEmpty ? 1 : 0,
            duration: AppMotion.of(context, AppMotion.medium),
            child: const _EmptyState(),
          ),
        ),
      ],
    );
  }
}

class ImageTile extends StatelessWidget {
  const ImageTile({
    super.key,
    required this.item,
    required this.fresh,
    required this.onTap,
  });

  final ImageItem item;

  /// Just arrived: show a green ring and a "New" badge for a moment.
  final bool fresh;
  final ValueChanged<Rect?> onTap;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.medium);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: duration,
                  placeholder: (_, _) => const SkeletonBox(),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: AppColors.placeholder,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedContainer(
                  duration: duration,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: fresh ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: AnimatedOpacity(
                  opacity: fresh ? 1 : 0,
                  duration: duration,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Builder(
                  builder: (tileContext) => InkWell(
                    onTap: () {
                      final box = tileContext.findRenderObject() as RenderBox?;
                      onTap(
                        box == null || !box.hasSize
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.referenceName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _Header()),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid.builder(
            gridDelegate: _gridDelegate,
            itemCount: 6,
            itemBuilder: (context, index) => const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AspectRatio(aspectRatio: 1, child: SkeletonBox()),
                SizedBox(height: 10),
                SizedBox(
                  width: 64,
                  height: 10,
                  child: SkeletonBox(borderRadius: 4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No images yet',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Upload one and it shows up here instantly.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.upload),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Upload a photo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message ?? 'Could not load images',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.read<ImagesBloc>().add(
                const ImagesSubscriptionRequested(),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
