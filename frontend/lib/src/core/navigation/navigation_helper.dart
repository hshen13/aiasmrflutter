import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../routes/route_constants.dart';
import '../providers/app_state.dart';

class NavigationHelper {
  static void goToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      Routes.home,
      (route) => false,
    );
  }

  static void goToChat(BuildContext context, WidgetRef ref) {
    final appState = ref.read(appStateProvider);
    if (!appState.isAuthenticated) {
      goToLogin(context, onLoginSuccess: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.chat,
          (route) => false,
        );
      });
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.chat,
      (route) => false,
    );
  }

  static void goToChatDetail(BuildContext context, WidgetRef ref, String chatId, String characterId) {
    final appState = ref.read(appStateProvider);
    if (!appState.isAuthenticated) {
      goToLogin(context, onLoginSuccess: () {
        Navigator.pushNamed(
          context,
          Routes.chatDetail,
          arguments: {
            'chatId': chatId,
            'characterId': characterId,
          },
        );
      });
      return;
    }
    Navigator.pushNamed(
      context,
      Routes.chatDetail,
      arguments: {
        'chatId': chatId,
        'characterId': characterId,
      },
    );
  }

  static void goToProfile(BuildContext context, WidgetRef ref) {
    final appState = ref.read(appStateProvider);
    if (!appState.isAuthenticated) {
      goToLogin(context, onLoginSuccess: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.profile,
          (route) => false,
        );
      });
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.profile,
      (route) => false,
    );
  }

  static void goToLogin(BuildContext context, {VoidCallback? onLoginSuccess}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.login,
      (route) => false,
      arguments: onLoginSuccess,
    );
  }

  static void goToRegister(BuildContext context) {
    Navigator.pushNamed(context, Routes.register);
  }

  static void goToCreate(BuildContext context, WidgetRef ref) {
    final appState = ref.read(appStateProvider);
    if (!appState.isAuthenticated) {
      goToLogin(context, onLoginSuccess: () {
        Navigator.pushNamed(context, Routes.create);
      });
      return;
    }
    Navigator.pushNamed(context, Routes.create);
  }

  static void goToTest(BuildContext context) {
    Navigator.pushNamed(context, Routes.test);
  }

  static void goToAnonymousProfile(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.anonymousProfile,
      (route) => false,
    );
  }

  static void goToChatWithCharacter(BuildContext context, WidgetRef ref, String characterId) async {
    final appState = ref.read(appStateProvider);
    if (!appState.isAuthenticated) {
      goToLogin(context, onLoginSuccess: () {
        Navigator.pushNamed(
          context,
          Routes.chatDetail,
          arguments: {
            'characterId': characterId,
          },
        );
      });
      return;
    }
    try {
      Navigator.pushNamed(
        context,
        Routes.chatDetail,
        arguments: {
          'characterId': characterId,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建聊天失败: ${e.toString()}')),
      );
    }
  }

  static void pop(BuildContext context) {
    Navigator.pop(context);
  }

  static void popToRoot(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.home,
      (route) => false,
    );
  }
}
