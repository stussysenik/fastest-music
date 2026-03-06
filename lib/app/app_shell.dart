import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared_widgets/mini_player.dart';
import '../core/startup/prefetch_pipeline.dart';

/// App shell with bottom navigation and startup prefetch pipeline.
///
/// ## Why ConsumerStatefulWidget? (educational)
///
/// We need `initState` to schedule the prefetch pipeline as a post-frame
/// callback (runs once after the first frame), and we need `ref` to
/// access Riverpod providers. ConsumerStatefulWidget gives us both.
///
/// The pipeline collects all artwork URLs from cached data and preloads
/// them into Flutter's ImageCache. This means when the user navigates
/// to any tab, images appear instantly from RAM — no shimmer, no delay.
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Schedule prefetch after the first frame so we don't block rendering.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PrefetchPipeline.runPostFrame(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: widget.navigationShell.currentIndex,
            onTap: (index) {
              widget.navigationShell.goBranch(
                index,
                initialLocation:
                    index == widget.navigationShell.currentIndex,
              );
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_fill),
                label: 'Playing',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Browse',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.public),
                label: 'World',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Library',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
