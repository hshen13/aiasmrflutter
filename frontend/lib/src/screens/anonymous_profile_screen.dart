import 'package:flutter/material.dart';
import '../core/navigation/navigation_helper.dart';

class AnonymousProfileScreen extends StatelessWidget {
  const AnonymousProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Color(0xFFFF4D9C),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '登录后可以创建自己的角色',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => NavigationHelper.goToLogin(context),
                          child: const Text('登录'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => NavigationHelper.goToRegister(context),
                          child: const Text('注册'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Features Section
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '登录后可以使用的功能',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('与AI角色聊天'),
                  subtitle: const Text('创建专属于你的AI角色'),
                  onTap: () => NavigationHelper.goToLogin(context),
                ),
                ListTile(
                  leading: const Icon(Icons.create_outlined),
                  title: const Text('创建角色'),
                  subtitle: const Text('定制你的专属AI角色'),
                  onTap: () => NavigationHelper.goToLogin(context),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('收藏角色'),
                  subtitle: const Text('保存你喜欢的AI角色'),
                  onTap: () => NavigationHelper.goToLogin(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Help Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('帮助与反馈'),
                  onTap: () {
                    // TODO: Implement help and feedback
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('关于我们'),
                  onTap: () {
                    // TODO: Implement about page
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
