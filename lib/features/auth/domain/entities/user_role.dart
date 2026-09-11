enum UserRole {
  employee,
  manager,
  cashier,
  owner,
  admin;

  static UserRole fromString(dynamic role) {
    final clean = (role ?? '').toString().toUpperCase().trim();
    if (clean.contains('OWNER') || clean.contains('ADMIN')) {
      return UserRole.owner;
    } else if (clean.contains('MANAGER') || clean.contains('MGR')) {
      return UserRole.manager;
    } else if (clean.contains('CASHIER') || clean.contains('FINANCE') || clean.contains('ACC')) {
      return UserRole.cashier;
    }
    return UserRole.employee;
  }

  String get displayName {
    switch (this) {
      case UserRole.owner:
      case UserRole.admin:
        return 'OWNER';
      case UserRole.manager:
        return 'MANAGER';
      case UserRole.cashier:
        return 'CASHIER';
      case UserRole.employee:
        return 'EMPLOYEE';
    }
  }
}
