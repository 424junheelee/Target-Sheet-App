import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wlddbbhvghfsyppuekqv.supabase.co',
    publishableKey: 'sb_publishable_dUkPiMWkyk8AXjk-Kta2-g_s94BTWde',
  );

  runApp(const ProviderScope(child: TargetSheetApp()));
}

class TargetSheetApp extends StatelessWidget {
  const TargetSheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TargetSheet',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBA7517),
          surface: const Color(0xFFF7F2E8),
        ),
        useMaterial3: true,
      ),
    );
  }
}
