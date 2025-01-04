import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_state.dart';
import '../core/providers/player_state.dart';
import '../models/audio.dart';
import '../models/character.dart';
import '../routes/route_constants.dart';
import '../widgets/main_layout.dart';

class CircleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color.fromARGB(111, 255, 255, 255).withOpacity(0.4),
          const Color.fromARGB(132, 255, 255, 255).withOpacity(0.4),
          const Color.fromARGB(134, 255, 255, 255).withOpacity(0.4),
        ],
        stops: const [0.3, 0.6, 0.9],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), size.width * 0.06, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.8), size.width * 0.05, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.2), size.width * 0.06, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule data loading after the initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final appState = ref.read(appStateProvider.notifier);
      if (appState.state.isAuthenticated) {
        await Future.wait([
          appState.loadCharacters(),
          appState.fetchRecentlyPlayed(),
          appState.fetchTracks(),
        ]);
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载数据失败: ${e.toString()}'),
            action: SnackBarAction(
              label: '重试',
              onPressed: () {
                _loadData();
              },
            ),
          ),
        );
      }
    }
  }

  void _onSearch(String query) {
    // TODO: Implement search functionality
  }

  void _navigateToChat(BuildContext context, Character character) {
    Navigator.pushNamed(
      context,
      Routes.chatDetail,
      arguments: {
        'chatId': 'new',
        'characterId': character.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '首页',
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

          return Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  onChanged: _onSearch,
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
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                ),
              ),
              // Character list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: appState.characters.length,
                  itemBuilder: (context, index) {
                    final character = appState.characters[index];
                    final characterTracks = appState.recentlyPlayed
                        .where((item) => item.track.userId == character.id)
                        .take(2)
                        .toList();
                    return _buildCharacterCard(context, character, characterTracks);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context, Character character, List<RecentlyPlayed> recentTracks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: character.avatarOrImageUrl.isNotEmpty
                        ? NetworkImage(character.avatarOrImageUrl)
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: character.avatarOrImageUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              character.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${character.onlineTime}m',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '由 @${character.username} 创建',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        if (character.shortBio.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            character.shortBio,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Chat input section
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            height: 120,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient:  RadialGradient(
                      center: Alignment.topRight,
                      radius: 2,
                    colors: [
                   Color(0xFF9445C6).withOpacity(0.2),
                    Color(0xFF8A44A9).withOpacity(0.2),
                    Color.fromARGB(255, 168, 135, 166).withOpacity(0.2),
                           ],
                    stops: [0.3, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: CircleOverlayPainter(),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          '用语音和文字，与 ${character.name} 交流吧',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _navigateToChat(context, character),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color.fromARGB(255, 122, 108, 128).withOpacity(0.9),
                                  const Color.fromARGB(255, 119, 100, 122).withOpacity(0.9),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                character.waveformUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 24,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Audio tracks section
          Row(
            children: [
              Text(
                '【立体声】',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '和卡夫卡共度的周末',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildAudioTrack(
            context,
            Track(
              id: '1',
              title: '和卡夫卡共度的周末',
              description: '一起去约会吧。"她这么说着，眼神却不自觉地看向你。',
              audio_url: '/audio/1.mp3',
              artist: character.name,
              duration: 62,
              cover_url: character.avatarOrImageUrl,
              userId: character.id,
              username: character.username,
              userAvatar: character.avatarOrImageUrl,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          const SizedBox(height: 8),
          _buildAudioTrack(
            context,
            Track(
              id: '2',
              title: '和卡夫卡共度的周末',
              description: '一起去约会吧。"她这么说着，眼神却不自觉地看向你。',
              audio_url: '/audio/2.mp3',
              artist: character.name,
              duration: 62,
              cover_url: character.avatarOrImageUrl,
              userId: character.id,
              username: character.username,
              userAvatar: character.avatarOrImageUrl,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTrack(BuildContext context, Track track) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          ref.read(playerStateProvider.notifier).playTrack(track);
        },
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: track.fullCoverUrl != null
                      ? Image.network(
                          track.fullCoverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[900],
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[900],
                        ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(track.duration / 60).floor()}min${(track.duration % 60).floor()}s',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.description ?? '一起去约会吧。"她这么说着，眼神却不自觉地看向你。',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
