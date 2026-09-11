class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';

  // Dashboards
  static const String dashboard = '/dashboard';
  static const String managerDashboard = '/manager-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String cashierDashboard = '/cashier-dashboard';
  static const String ownerDashboard = '/owner-dashboard';

  // Approvals & Expenses
  static const String pendingApprovals = '/pending-approvals';
  static const String expenses = '/expenses';
  static const String addExpense = '/add-expense';
  static const String expenseDetails = '/expense-details';

  // Reports & Misc
  static const String reports = '/reports';
  static const String reportDetails = '/report-details';
  static const String notifications = '/notifications';

  // Profile & Settings
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String settings = '/settings';
}
