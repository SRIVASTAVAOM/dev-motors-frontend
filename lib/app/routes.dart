import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/employee_dashboard.dart';
import '../features/dashboard/presentation/pages/manager_dashboard.dart';
import '../features/dashboard/presentation/pages/cashier_dashboard.dart';
import '../features/dashboard/presentation/pages/owner_dashboard.dart';

Map<String, WidgetBuilder> getAppRoutes() {
  return {
    AppRoutes.login: (context) => const LoginPage(),
    AppRoutes.dashboard: (context) => const EmployeeDashboard(),
    AppRoutes.managerDashboard: (context) => const ManagerDashboard(),
    AppRoutes.cashierDashboard: (context) => const CashierDashboard(),
    AppRoutes.ownerDashboard: (context) => const OwnerDashboard(),
  };
}
