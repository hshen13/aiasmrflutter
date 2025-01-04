import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routes/route_constants.dart';
import '../core/providers/player_state.dart';
import 'bottom_nav_bar.dart';
import 'global_player.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;

  const MainLayout({
    super.key, 
    required this.child,
    this.title,
    this.actions,
  });

  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? Routes.home;
    switch (route) {
      case Routes.home:
        return 0;
      case Routes.discover:
        return 1;
      case Routes.fullPlayer:
        return 2;
      case Routes.chatList:
        return 3;
      case Routes.profile:
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: title != null ? AppBar(
        backgroundColor: Colors.black,
        title: Text(
          title!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: actions,
      ) : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: child,
              ),
            ),
            if (playerState.currentTrack != null)
              const GlobalPlayer(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _getCurrentIndex(context),
      ),
    );
  }
}
