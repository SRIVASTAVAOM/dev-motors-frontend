class UserRoles {
  UserRoles._();

  static const String owner = 'owner';
  static const String manager = 'manager';
  static const String cashier = 'cashier';
  static const String employee = 'employee';

  // Backward compatibility with the old build.
  static const String admin = 'admin';
}
