import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/asmr_post_card.dart';
import '../widgets/main_layout.dart';
import '../models/audio.dart';
import '../core/providers/app_state.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final appState = ref.read(appStateProvider);
        if (appState.isAuthenticated) {
          await ref.read(appStateProvider.notifier).fetchTracks();
        } else {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('加载音频失败: ${e.toString()}'),
              action: SnackBarAction(
                label: '重试',
                onPressed: () {
                  ref.read(appStateProvider.notifier).fetchTracks();
                },
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '发现',
      child: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索音频、角色或创作者',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                ),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          // Content list
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final appState = ref.watch(appStateProvider);
                if (appState.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                if (appState.tracks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '暂无音频',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(appStateProvider.notifier).fetchTracks(),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(appStateProvider.notifier).fetchTracks(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: appState.tracks.length,
                    itemBuilder: (context, index) {
                      final track = appState.tracks[index];
                      return ASMRPostCard(track: track);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
