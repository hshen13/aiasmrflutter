import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/app_state.dart';
import 'core/storage/storage_service.dart';
import 'routes/routes.dart';
import 'widgets/global_player.dart';
import 'widgets/bottom_nav_bar.dart';
import 'core/di/service_locator.dart';
import 'core/api/api_client.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'routes/route_constants.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'ASMR App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
        ],
        initialRoute: Routes.home,
        onGenerateRoute: generateRoute,
        builder: (context, child) => child!,
      ),
    );
  }
}
