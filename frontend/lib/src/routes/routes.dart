import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_state.dart';
import '../screens/home_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/create_screen.dart';
import '../screens/test_connection_screen.dart';
import '../screens/anonymous_profile_screen.dart';
import '../screens/audio_player_screen.dart';
import '../screens/full_player_screen.dart';
import '../models/audio.dart';
import '../widgets/main_layout.dart';
import 'route_constants.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  debugPrint('Generating route for: ${settings.name}');
  
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          // Check authentication for protected routes
          final appState = ref.read(appStateProvider);
          final isAuthenticated = appState.isAuthenticated;
          
          debugPrint('Route: ${settings.name}');
          debugPrint('Authentication status: ${isAuthenticated ? 'Authenticated' : 'Not authenticated'}');
          debugPrint('Arguments: ${settings.arguments}');
          
          // Handle authentication redirection for protected routes only
          if (Routes.redirectToLoginRoutes.contains(settings.name) && !isAuthenticated) {
            debugPrint('Redirecting to login screen (unauthenticated access to ${settings.name})');
            return LoginScreen(
              onLoginSuccess: () {
                debugPrint('Login successful, navigating to ${settings.name}');
                if (settings.name == Routes.profile) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.profile,
                    (route) => false,
                  );
                } else {
                  Navigator.pushReplacementNamed(
                    context, 
                    settings.name!,
                    arguments: settings.arguments,
                  );
                }
              },
            );
          }

          // Build the screen
          try {
            Widget screen = _buildScreen(settings);
            
            return screen;
          } catch (e, stackTrace) {
            debugPrint('Error building route ${settings.name}: $e');
            debugPrint('Stack trace: $stackTrace');
            
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                title: const Text(
                  '错误',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '页面加载失败',
                      style: TextStyle(
                        color: Colors.red[100],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, Routes.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('返回首页'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      );
    },
  );
}

Widget _buildScreen(RouteSettings settings) {
  switch (settings.name) {
    case Routes.home:
      return const HomeScreen();
      
    case Routes.discover:
      return const DiscoverScreen();
      
    case Routes.chatList:
      return const ChatListScreen();
      
    case Routes.profile:
      return const ProfileScreen();
      
    case Routes.chatDetail:
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        throw ArgumentError('Chat detail requires chatId and characterId arguments');
      }
      final chatId = args['chatId']?.toString();
      final characterId = args['characterId']?.toString();
      if (chatId == null || characterId == null) {
        throw ArgumentError('Invalid chat detail arguments');
      }
      return ChatDetailScreen(
        chatId: chatId,
        characterId: characterId,
      );
      
    case Routes.login:
      if (settings.arguments is VoidCallback) {
        return LoginScreen(onLoginSuccess: settings.arguments as VoidCallback);
      }
      return const LoginScreen();
      
    case Routes.register:
      return const RegisterScreen();
      
    case Routes.create:
      return const CreateScreen();
      
    case Routes.test:
      return const TestConnectionScreen();
      
    case Routes.anonymousProfile:
      return const AnonymousProfileScreen();
      
    case Routes.audioPlayer:
      final track = settings.arguments as Track?;
      if (track == null) {
        throw ArgumentError('Audio player requires a track argument');
      }
      return AudioPlayerScreen(track: track);

    case Routes.fullPlayer:
      return const FullPlayerScreen();
      
    default:
      debugPrint('Route not found: ${settings.name}');
      return const HomeScreen();
  }
}
