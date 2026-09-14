import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/employee_dashboard.dart';
import 'features/dashboard/presentation/pages/manager_dashboard.dart';
import 'features/dashboard/presentation/pages/cashier_dashboard.dart';
import 'features/dashboard/presentation/pages/owner_dashboard.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const DevMotorsApp());
}

class DevMotorsApp extends StatelessWidget {
  const DevMotorsApp({super.key});

  Widget _getDashboardByRole() {
    final auth = AuthProvider();
    final user = auth.user;
    final role = (user?['role'] ?? '').toString().toUpperCase();

    if (role == 'OWNER' || role == 'ADMIN') {
      return const OwnerDashboard();
    } else if (role == 'MANAGER') {
      return const ManagerDashboard();
    } else if (role == 'CASHIER') {
      return const CashierDashboard();
    } else {
      return const EmployeeDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dev Motors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xffF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffD32F2F),
          primary: const Color(0xffD32F2F),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => _getDashboardByRole(),
        '/employee': (context) => const EmployeeDashboard(),
        '/manager': (context) => const ManagerDashboard(),
        '/cashier': (context) => const CashierDashboard(),
        '/owner': (context) => const OwnerDashboard(),
      },
    );
  }
}
