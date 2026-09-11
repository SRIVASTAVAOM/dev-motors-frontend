import 'package:flutter/material.dart';

import 'app_router.dart';
import 'app_routes.dart';

class DevMotorsApp extends StatelessWidget {
  const DevMotorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dev Motors",

      debugShowCheckedModeBanner: false,

      initialRoute: AppRoutes.splash,

      onGenerateRoute: AppRouter.generateRoute,

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xffF5F7FB),
      ),
    );
  }
}