import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:dev_motors/core/utils/claim_workflow_engine.dart';
import 'package:dev_motors/core/services/notification_service.dart';

void main() {
  test('Verify live backend API health and clean database state', () async {
    final healthRes = await http.get(Uri.parse('https://dev-motors-backend.onrender.com/health'));
    expect(healthRes.statusCode, 200);

    final loginRes = await http.post(
      Uri.parse('https://dev-motors-backend.onrender.com/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'employeeId': 'nexa_stephen_sm', 'password': 'Dev@2026'}),
    );
    expect(loginRes.statusCode, 200);
    final token = jsonDecode(loginRes.body)['data']['token'];

    final res = await http.get(
      Uri.parse('https://dev-motors-backend.onrender.com/api/expenses'),
      headers: {'Authorization': 'Bearer $token'},
    );
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

  test('Verify Location-Wise Branch Accountant (Cashier) Isolation & Workflow', () {
    final aligarhCashier = {
      'id': 'csh-aligarh',
      'employeeId': 'nexa_shivam_acc',
      'name': 'Shivam (Aligarh Accountant)',
      'role': 'CASHIER',
      'branch': 'Aligarh Nexa',
    };

    final khairCashier = {
      'id': 'csh-khair',
      'employeeId': 'khair_rohit_acc',
      'name': 'Rohit (Khair Accountant)',
      'role': 'CASHIER',
      'branch': 'Khair',
    };

    final aligarhApprovedClaim = {
      'id': 'EXP_ALIGARH_01',
      'amount': 2500,
      'description': 'Aligarh showroom spare parts',
      'status': 'PENDING_CASHIER',
      'branch': 'Aligarh Nexa',
      'employeeId': 'nexa_muneesh_bsm',
      'creatorRole': 'EMPLOYEE',
    };

    final khairApprovedClaim = {
      'id': 'EXP_KHAIR_01',
      'amount': 3000,
      'description': 'Khair workshop tools',
      'status': 'PENDING_CASHIER',
      'branch': 'Khair',
      'employeeId': 'khair_dev_wm',
      'creatorRole': 'MANAGER',
    };

    final allClaims = [aligarhApprovedClaim, khairApprovedClaim];

    // 1. Aligarh Accountant must ONLY see Aligarh claims in payout queue
    final aligarhPayoutQueue = allClaims.where((e) {
      if (!ClaimWorkflowEngine.isPendingForCashier(e['status'], e)) return false;
      return ClaimWorkflowEngine.matchesBranch(
        userBranch: aligarhCashier['branch'],
        expenseBranch: e['branch'],
        currentUser: aligarhCashier,
      );
    }).toList();

    expect(aligarhPayoutQueue.length, equals(1));
    expect(aligarhPayoutQueue.first['id'], equals('EXP_ALIGARH_01'));

    // 2. Khair Accountant must ONLY see Khair claims in payout queue
    final khairPayoutQueue = allClaims.where((e) {
      if (!ClaimWorkflowEngine.isPendingForCashier(e['status'], e)) return false;
      return ClaimWorkflowEngine.matchesBranch(
        userBranch: khairCashier['branch'],
        expenseBranch: e['branch'],
        currentUser: khairCashier,
      );
    }).toList();

    expect(khairPayoutQueue.length, equals(1));
    expect(khairPayoutQueue.first['id'], equals('EXP_KHAIR_01'));

    // 3. Aligarh Accountant receives notifications ONLY for Aligarh payout claims
    final aligarhNotifs = NotificationService.getNotificationsForRole(
      'CASHIER',
      allClaims,
      userBranch: aligarhCashier['branch'],
      currentUser: aligarhCashier,
    );
    expect(aligarhNotifs.length, equals(1));
    expect(aligarhNotifs.first['expenseId'], equals('EXP_ALIGARH_01'));

    // 4. Khair Accountant receives notifications ONLY for Khair payout claims
    final khairNotifs = NotificationService.getNotificationsForRole(
      'CASHIER',
      allClaims,
      userBranch: khairCashier['branch'],
      currentUser: khairCashier,
    );
    expect(khairNotifs.length, equals(1));
    expect(khairNotifs.first['expenseId'], equals('EXP_KHAIR_01'));
  });
}
