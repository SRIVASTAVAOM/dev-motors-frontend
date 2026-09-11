import 'package:flutter/material.dart';
import '../../features/dashboard/presentation/pages/employee_dashboard.dart';
import '../../features/dashboard/presentation/pages/manager_dashboard.dart';
import '../../features/dashboard/presentation/pages/cashier_dashboard.dart';
import '../../features/dashboard/presentation/pages/owner_dashboard.dart';
import '../../features/auth/presentation/pages/login_page.dart';

class RoleRouter {
  static String getInitialRouteForRole(String role) {
    switch (role.toLowerCase()) {
      case 'employee':
        return '/employee-dashboard';
      case 'manager':
        return '/manager-dashboard';
      case 'cashier':
        return '/cashier-dashboard';
      case 'owner':
      case 'admin':
        return '/owner-dashboard';
      default:
        return '/login';
    }
  }

  static Widget getDashboardForRole(String role) {
    switch (role.toLowerCase()) {
      case 'employee':
        return const EmployeeDashboard();
      case 'manager':
        return const ManagerDashboard();
      case 'cashier':
        return const CashierDashboard();
      case 'owner':
      case 'admin':
        return const OwnerDashboard();
      default:
        return const LoginPage();
    }
  }
}
