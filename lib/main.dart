import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/battle_screen.dart';
import 'presentation/screens/add_word_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

final router = GoRouter(
  initialLocation: '/',
  routes: [
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

void main() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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