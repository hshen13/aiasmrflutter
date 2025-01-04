class Routes {
  // Route paths
  static const String home = '/';
  static const String discover = '/discover';
  static const String chat = '/chat';
  static const String chatDetail = '/chat/detail';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String register = '/register';
  static const String create = '/create';
  static const String test = '/test';
  static const String anonymousProfile = '/anonymous_profile';
  static const String audioPlayer = '/audio-player';
  static const String playlistDetail = '/playlist-detail';
  static const String fullPlayer = '/full-player';
  static const String chatList = '/chat-list';

  // Route titles
  static const String homeTitle = '首页';
  static const String discoverTitle = '发现';
  static const String chatTitle = '聊天';
  static const String profileTitle = '我的';
  static const String loginTitle = '登录';
  static const String registerTitle = '注册';
  static const String createTitle = '创建角色';
  static const String testTitle = '测试连接';
  static const String audioPlayerTitle = '正在播放';
  static const String fullPlayerTitle = '播放器';
  static const String chatListTitle = '聊天';

  // List of routes that require authentication
  static const List<String> authenticatedRoutes = [
    profile,
    audioPlayer,
    fullPlayer,
    chatList,
  ];

  // List of routes that should redirect to login if not authenticated
  static const List<String> redirectToLoginRoutes = [
    profile,
    audioPlayer,
    fullPlayer,
    chatList,
  ];

  // List of routes that should show the bottom navigation bar
  static const List<String> bottomNavBarRoutes = [
    home,
    discover,
    chatList,
    profile,
  ];

  // Default route when no match is found
  static const String defaultRoute = home;
}
