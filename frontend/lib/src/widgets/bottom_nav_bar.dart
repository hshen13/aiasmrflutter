import 'package:flutter/material.dart';
import '../routes/route_constants.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    this.onTap,
  }) : super(key: key);

  void _handleNavigation(BuildContext context, int index) {
    if (currentIndex == index) return;

    String route;
    switch (index) {
      case 0:
        route = Routes.home;
        break;
      case 1:
        route = Routes.discover;
        break;
      case 2:
        route = Routes.fullPlayer;
        break;
      case 3:
        route = Routes.chatList;
        break;
      case 4:
        route = Routes.profile;
        break;
      default:
        return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (r) => false,
      arguments: {'animate': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[700],
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        onTap: onTap ?? (index) => _handleNavigation(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: '发现',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.headphones_outlined),
            activeIcon: Icon(Icons.headphones),
            label: '播放',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '聊天',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
