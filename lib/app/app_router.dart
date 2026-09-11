import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/employee_dashboard.dart';
import '../features/dashboard/presentation/pages/manager_dashboard.dart';
import '../features/dashboard/presentation/pages/cashier_dashboard.dart';
import '../features/dashboard/presentation/pages/owner_dashboard.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const EmployeeDashboard());

      case AppRoutes.managerDashboard:
        return MaterialPageRoute(builder: (_) => const ManagerDashboard());

      case AppRoutes.cashierDashboard:
        return MaterialPageRoute(builder: (_) => const CashierDashboard());

      case AppRoutes.ownerDashboard:
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const OwnerDashboard());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Alias so both function names work seamlessly
  static Route<dynamic> onGenerateRoute(RouteSettings settings) => generateRoute(settings);
}
