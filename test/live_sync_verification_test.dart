import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:dev_motors/core/utils/claim_workflow_engine.dart';
import 'package:dev_motors/core/services/notification_service.dart';

void main() {
  test('Verify live sync data against ClaimWorkflowEngine & NotificationService', () async {
    final res = await http.get(Uri.parse('https://dev-motors-backend.onrender.com/api/expenses'));
    expect(res.statusCode, 200);

    final list = jsonDecode(res.body)['data'] as List;

    final mgrUser = {
      'id': 'khair_dev_wm',
      'employeeId': 'khair_dev_wm',
      'name': 'Dev Kumar Baghel',
      'role': 'MANAGER',
      'branch': 'Khair',
      'location': 'Khair'
    };

    // 1. My Claims verification
    final myClaims = list.where((e) => ClaimWorkflowEngine.isClaimCreatedByUser(e, mgrUser)).toList();
    expect(myClaims.length, greaterThanOrEqualTo(3));
    for (var c in myClaims) {
      expect(ClaimWorkflowEngine.isPendingForManager(c['status'], c), isFalse,
          reason: 'Manager claims must NEVER enter manager review queue');
      expect(ClaimWorkflowEngine.isPendingForOwner(c['status'], c), isTrue,
          reason: 'Manager claims must route directly to Owner queue');
    }

    // 2. Action Needed tab verification for Khair branch
    final pendingAll = list.where((e) {
      if (ClaimWorkflowEngine.isClaimCreatedByUser(e, mgrUser)) return false;
      return ClaimWorkflowEngine.isPendingForManager(e['status'], e);
    }).toList();

    final pendingKhair = pendingAll.where((e) {
      final expBranch = e['branch'] ?? (e['location'] is Map ? e['location']['name'] : e['location']);
      return ClaimWorkflowEngine.matchesBranch(userBranch: 'Khair', expenseBranch: expBranch);
    }).toList();

    // Self-created claims MUST NOT be in pendingKhair
    for (var c in pendingKhair) {
      expect(ClaimWorkflowEngine.isClaimCreatedByUser(c, mgrUser), isFalse);
    }

    // 3. Notification verification
    final notifs = NotificationService.getNotificationsForRole('MANAGER', list, userBranch: 'Khair', currentUser: mgrUser);
    for (var n in notifs) {
      // Must NOT contain Devendra Sharma or claims from other branches
      final title = (n['title'] ?? '').toString();
      expect(title.contains('Devendra Sharma'), isFalse,
          reason: 'Owner / Managing Director claims must not alert branch managers');
    }
  });
}
