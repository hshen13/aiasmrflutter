import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_state.dart';
import '../core/navigation/navigation_helper.dart';
import '../widgets/main_layout.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Widget _buildDefaultAvatar(dynamic user) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserContent(BuildContext context, AppStateData appState, WidgetRef ref) {
    final user = appState.user;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              '请先登录',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => NavigationHelper.goToLogin(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                '登录',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => NavigationHelper.goToRegister(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[400],
              ),
              child: const Text(
                '注册新账号',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipOval(
                child: user.fullAvatarUrl.isNotEmpty
                  ? Image.network(
                      user.fullAvatarUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(user),
                    )
                  : _buildDefaultAvatar(user),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${user.id}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: '设置',
                onTap: () {
                  // TODO: Navigate to settings
                },
              ),
              const Divider(height: 1, color: Color(0xFF3A3A3A)),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: '帮助与反馈',
                onTap: () {
                  // TODO: Navigate to help
                },
              ),
              const Divider(height: 1, color: Color(0xFF3A3A3A)),
              _buildMenuItem(
                icon: Icons.logout,
                title: '退出登录',
                showArrow: false,
                onTap: () async {
                  await ref.read(appStateProvider.notifier).logout();
                  if (context.mounted) {
                    NavigationHelper.goToLogin(context);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    return MainLayout(
      title: '我的',
      child: _buildUserContent(context, appState, ref),
    );
  }
}
