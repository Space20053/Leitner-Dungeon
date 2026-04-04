import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/battle_screen.dart';
import 'presentation/screens/add_word_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
// 1. Додаємо імпорт window_manager
import 'package:window_manager/window_manager.dart'; 

final router = GoRouter(
  initialLocation: '/',
  routes:[
    GoRoute(
      path: '/',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/battle/:count',
      builder: (context, state) {
        final count = int.parse(state.pathParameters['count']!);
        return BattleScreen(sessionCount: count);
      },
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddWordScreen(),
    ),
  ],
);

// 2. Додаємо async до main
void main() async {
  // 3. Обов'язкова ініціалізація віджетів перед викликом плагінів та асинхронним кодом
  WidgetsFlutterBinding.ensureInitialized();

  // Налаштування для десктопу (БД та Вікно)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    // Ініціалізація бази даних
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // 4. Ініціалізація та налаштування вікна гри
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720), // Розмір, якщо користувач вийде з повноекранного режиму
      center: true,
      title: 'Leitner Dungeon',
    );

windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      
      // ОДИН З ЦИХ ДВОХ ВАРІАНТІВ:

      // Варіант 1: Розгорнути вікно (панель з хрестиком зверху ЗАЛИШИТЬСЯ)
      await windowManager.maximize(); 

      // Варіант 2: Справжній режим гри (панель Windows зверху ЗНИКНЕ)
      // await windowManager.setFullScreen(true); 
   });
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Leitner Dungeon',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFD4A853),
          surface: const Color(0xFF1A1209),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0A06),
        fontFamily: 'Georgia',
      ),
    );
  }
}