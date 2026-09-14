import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dev_motors/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationService.resetForTesting();
  });

  test('NotificationService: clearAllForRole clears all notifications and unread count becomes 0', () {
    final expenses = [
      {
        'id': 'exp-1',
        'title': 'Test Claim 1',
        'amount': 1500,
        'status': 'PENDING_OWNER',
        'employeeId': 'nexa_muneesh_bsm',
        'employee': {'name': 'Muneesh', 'employeeId': 'nexa_muneesh_bsm'},
      },
      {
        'id': 'exp-2',
        'title': 'Test Claim 2',
        'amount': 2500,
        'status': 'PENDING_OWNER',
        'employeeId': 'main_arman_gm',
        'employee': {'name': 'Arman', 'employeeId': 'main_arman_gm', 'role': 'MANAGER'},
      },
    ];

    // 1. Before clear, Owner sees notifications
    final before = NotificationService.getNotificationsForRole('OWNER', expenses);
    expect(before.length, 2);

    // 2. Clear all notifications for Owner
    NotificationService.clearAllForRole('OWNER', expenses);

    // 3. After clear, Owner sees 0 notifications
    final after = NotificationService.getNotificationsForRole('OWNER', expenses);
    expect(after.length, 0);
  });

  test('NotificationService: dismiss individual notification removes only that notification', () {
    final expenses = [
      {
        'id': 'exp-1',
        'title': 'Claim 1',
        'amount': 500,
        'status': 'PENDING_OWNER',
        'employee': {'name': 'Muneesh'},
      },
      {
        'id': 'exp-2',
        'title': 'Claim 2',
        'amount': 1200,
        'status': 'PENDING_OWNER',
        'employee': {'name': 'Rahul'},
      },
    ];

    final before = NotificationService.getNotificationsForRole('OWNER', expenses);
    expect(before.length, 2);

    // Dismiss first notification
    final firstId = before.first['id'].toString();
    NotificationService.dismissNotification('OWNER', firstId);

    final after = NotificationService.getNotificationsForRole('OWNER', expenses);
    expect(after.length, 1);
    expect(after.first['id'].toString(), isNot(firstId));
  });

  test('NotificationService: clearAllForRole clears for MANAGER, CASHIER, and EMPLOYEE', () {
    final expenses = [
      {
        'id': 'exp-10',
        'title': 'Fuel Claim',
        'amount': 800,
        'status': 'PENDING_MANAGER',
        'employeeId': 'emp-1',
        'employee': {'name': 'Rohan', 'employeeId': 'emp-1'},
      },
      {
        'id': 'exp-11',
        'title': 'Travel Claim',
        'amount': 1200,
        'status': 'PENDING_CASHIER',
        'employeeId': 'emp-2',
        'employee': {'name': 'Pooja', 'employeeId': 'emp-2'},
      },
      {
        'id': 'exp-12',
        'title': 'Stationery',
        'amount': 300,
        'status': 'REJECTED',
        'employeeId': 'emp-3',
        'employee': {'name': 'Suresh', 'employeeId': 'emp-3'},
      },
    ];

    // Manager test
    final mgrBefore = NotificationService.getNotificationsForRole('MANAGER', expenses);
    expect(mgrBefore.length, 1);
    NotificationService.clearAllForRole('MANAGER', expenses);
    expect(NotificationService.getNotificationsForRole('MANAGER', expenses).length, 0);

    // Cashier test
    final cshBefore = NotificationService.getNotificationsForRole('CASHIER', expenses);
    expect(cshBefore.length, 1);
    NotificationService.clearAllForRole('CASHIER', expenses);
    expect(NotificationService.getNotificationsForRole('CASHIER', expenses).length, 0);

    // Employee test (for their own rejected claim)
    final empUser = {'id': 'emp-3', 'employeeId': 'emp-3', 'name': 'Suresh'};
    final empBefore = NotificationService.getNotificationsForRole('EMPLOYEE', expenses, currentUser: empUser);
    expect(empBefore.length, 1);
    NotificationService.clearAllForRole('EMPLOYEE', expenses, currentUser: empUser);
    expect(NotificationService.getNotificationsForRole('EMPLOYEE', expenses, currentUser: empUser).length, 0);
  });
}
