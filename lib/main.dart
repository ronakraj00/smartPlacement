import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_placement/providers/auth_provider.dart';
import 'package:smart_placement/routes/app_router.dart';

void main() {
  runApp(const SmartPlacementApp());
}

class SmartPlacementApp extends StatelessWidget {
  const SmartPlacementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.createRouter(context);
          return MaterialApp.router(
            title: 'Smart Placement',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1565C0),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1565C0),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
