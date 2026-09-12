import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:dev_motors/core/utils/claim_workflow_engine.dart';
import 'package:dev_motors/core/services/notification_service.dart';

void main() {
  test('Verify live backend API health and clean database state', () async {
    final res = await http.get(Uri.parse('https://dev-motors-backend.onrender.com/api/expenses'));
    expect(res.statusCode, 200);

    final decoded = jsonDecode(res.body);
    expect(decoded['success'], isTrue);
    expect(decoded['data'], isA<List>());
  });

  test('Verify Complete Sequential Flow (Emp -> Mgr -> Owner -> Cashier -> Paid) & Notifications', () {
    final empUser = {
      'id': 'emp-001',
      'employeeId': 'EMP001',
      'name': 'Rahul Verma',
      'role': 'EMPLOYEE',
      'branch': 'Aligarh Nexa',
    };

    final mgrUser = {
      'id': 'mgr-001',
      'employeeId': 'MGR001',
      'name': 'Muneesh Kumar (BSM)',
      'role': 'MANAGER',
      'branch': 'Aligarh Nexa',
    };

    final seniorCashierUser = {
      'id': 'csh-001',
      'employeeId': 'CASH001',
      'name': 'Suresh Chandra (Chief Cashier & Finance)',
      'role': 'CASHIER',
      'branch': 'Kanpur Main Dealership',
    };

    // Stage 1: Employee creates expense (PENDING_MANAGER)
    final claim = {
      'id': 'EXP_101',
      'amount': 1500,
      'description': 'Showroom client hospitality',
      'category': 'Hospitality',
      'status': 'PENDING_MANAGER',
      'branch': 'Aligarh Nexa',
      'employeeId': 'EMP001',
      'employeeName': 'Rahul Verma',
      'creatorRole': 'EMPLOYEE',
    };

    expect(ClaimWorkflowEngine.isPendingForManager(claim['status'], claim), isTrue);
    expect(ClaimWorkflowEngine.isPendingForOwner(claim['status'], claim), isFalse);
    expect(ClaimWorkflowEngine.isPendingForCashier(claim['status'], claim), isFalse);

    // Manager receives notification
    final mgrNotifs1 = NotificationService.getNotificationsForRole(
      'MANAGER',
      [claim],
      userBranch: 'Aligarh Nexa',
      currentUser: mgrUser,
    );
    expect(mgrNotifs1.any((n) => n['type'] == 'PENDING_APPROVAL'), isTrue);

    // Stage 2: Manager approves -> status becomes PENDING_OWNER
    final claimStage2 = Map<String, dynamic>.from(claim)..['status'] = 'PENDING_OWNER';
    expect(ClaimWorkflowEngine.isPendingForManager(claimStage2['status'], claimStage2), isFalse);
    expect(ClaimWorkflowEngine.isPendingForOwner(claimStage2['status'], claimStage2), isTrue);
    expect(ClaimWorkflowEngine.isPendingForCashier(claimStage2['status'], claimStage2), isFalse);

    // Employee receives "Approved by Manager" notification
    final empNotifsStage2 = NotificationService.getNotificationsForRole(
      'EMPLOYEE',
      [claimStage2],
      currentUser: empUser,
    );
    expect(empNotifsStage2.any((n) => n['title'].toString().contains('Approved by Manager')), isTrue);

    // Stage 3: Owner approves -> status becomes PENDING_CASHIER
    final claimStage3 = Map<String, dynamic>.from(claim)..['status'] = 'PENDING_CASHIER';
    expect(ClaimWorkflowEngine.isPendingForManager(claimStage3['status'], claimStage3), isFalse);
    expect(ClaimWorkflowEngine.isPendingForOwner(claimStage3['status'], claimStage3), isFalse);
    expect(ClaimWorkflowEngine.isPendingForCashier(claimStage3['status'], claimStage3), isTrue);

    // Employee receives "Approved by Owner" notification
    final empNotifsStage3 = NotificationService.getNotificationsForRole(
      'EMPLOYEE',
      [claimStage3],
      currentUser: empUser,
    );
    expect(empNotifsStage3.any((n) => n['title'].toString().contains('Approved by Owner')), isTrue);

    // Senior Cashier (CASH001 from Kanpur) sees claim from Aligarh Nexa via universal oversight
    final cashierNotifs = NotificationService.getNotificationsForRole(
      'CASHIER',
      [claimStage3],
      userBranch: 'Kanpur Main Dealership',
      currentUser: seniorCashierUser,
    );
    expect(cashierNotifs.any((n) => n['type'] == 'READY_PAYMENT'), isTrue);

    // Stage 4: Cashier marks as PAID / Disbursed
    final claimStage4 = Map<String, dynamic>.from(claim)..['status'] = 'PAID';
    expect(ClaimWorkflowEngine.isSettledOrRejected(claimStage4['status'], claimStage4), isTrue);

    // Creator receives "Claim Disbursed & Settled" notification
    final empNotifsStage4 = NotificationService.getNotificationsForRole(
      'EMPLOYEE',
      [claimStage4],
      currentUser: empUser,
    );
    expect(empNotifsStage4.any((n) => n['type'] == 'PAID'), isTrue);
  });
}
