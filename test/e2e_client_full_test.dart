// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:dev_motors/core/utils/claim_workflow_engine.dart';
import 'package:dev_motors/core/services/notification_service.dart';

void main() {
  const baseUrl = 'https://dev-motors-backend.onrender.com/api';
  const defaultPassword = 'Dev@2026';

  group('Client Full End-to-End Workflow Verification', () {
    String? employeeToken;
    Map<String, dynamic>? employeeProfile;
    String? managerToken;
    Map<String, dynamic>? managerProfile;
    String? ownerToken;
    Map<String, dynamic>? ownerProfile;
    String? cashierToken;
    Map<String, dynamic>? cashierProfile;

    String? testExpenseId;
    String? managerSelfExpenseId;

    // 1. Employee Login
    test('1. Client Test: Employee logs in successfully', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': 'nexa_muneesh_bsm',
          'password': defaultPassword,
        }),
      );
      expect(res.statusCode, 200, reason: 'Employee login must succeed');
      final data = jsonDecode(res.body)['data'];
      employeeToken = data['token'];
      employeeProfile = data['user'];
      expect(employeeToken, isNotNull);
      expect(employeeProfile?['role'], 'EMPLOYEE');
      print('✅ 1. Employee Logged In: ${employeeProfile?['name']} (${employeeProfile?['employeeId']})');
    });

    // 2. Employee Submits Claim
    test('2. Client Test: Employee submits new expense claim with receipt', () async {
      expect(employeeToken, isNotNull);
      final res = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $employeeToken',
        },
        body: jsonEncode({
          'amount': 1250,
          'description': 'E2E Client Test - Client Showroom Refreshments',
          'categoryId': 'b87165b9-fc92-4444-8573-13240e421837',
          'location': 'Aligarh Nexa',
          'receiptUrl': 'https://devmotors-assets.s3.amazonaws.com/receipts/bill.png',
          'receiptFileName': 'tea_snack_bill.jpg',
        }),
      );
      expect(res.statusCode, anyOf([200, 201]), reason: 'Expense creation must succeed');
      final body = jsonDecode(res.body);
      final expData = body['data'] ?? body;
      testExpenseId = expData['id'] ?? expData['_id'];
      expect(testExpenseId, isNotNull);
      expect(expData['amount'], 1250);
      expect(expData['status'], 'PENDING_MANAGER');
      print('✅ 2. Claim Created: ID $testExpenseId, Amount: ₹1250, Status: PENDING_MANAGER');
    });

    // 3. Manager Login & Queue Verification
    test('3. Client Test: Branch Manager logs in and verifies Action Needed queue', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': 'nexa_stephen_sm',
          'password': defaultPassword,
        }),
      );
      expect(res.statusCode, 200, reason: 'Manager login must succeed');
      final data = jsonDecode(res.body)['data'];
      managerToken = data['token'];
      managerProfile = data['user'];
      expect(managerToken, isNotNull);
      expect(managerProfile?['role'], 'MANAGER');

      // Fetch pending expenses for Manager
      final expRes = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: {'Authorization': 'Bearer $managerToken'},
      );
      expect(expRes.statusCode, 200);
      final list = jsonDecode(expRes.body)['data'] as List;

      // Ensure test expense appears in Manager queue
      final claimInQueue = list.firstWhere(
        (e) => (e['id'] == testExpenseId || e['_id'] == testExpenseId),
        orElse: () => null,
      );
      expect(claimInQueue, isNotNull, reason: 'Employee claim must appear in branch manager queue');
      expect(ClaimWorkflowEngine.isPendingForManager(claimInQueue['status'], claimInQueue), isTrue);
      print('✅ 3. Manager Logged In: Claim verified in Action Needed Queue for Aligarh Nexa');
    });

    // 4. Manager Approves Employee Claim
    test('4. Client Test: Manager approves claim -> moves to PENDING_OWNER', () async {
      expect(testExpenseId, isNotNull);
      final res = await http.post(
        Uri.parse('$baseUrl/expenses/$testExpenseId/approval'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $managerToken',
        },
        body: jsonEncode({
          'action': 'APPROVED_1',
          'comments': 'Verified hospitality bills by Stephen (SM)',
        }),
      );
      expect(res.statusCode, 200, reason: 'Manager approval must succeed');

      // Verify status changed to PENDING_OWNER
      final expRes = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: {'Authorization': 'Bearer $managerToken'},
      );
      final list = jsonDecode(expRes.body)['data'] as List;
      final updatedClaim = list.firstWhere((e) => e['id'] == testExpenseId);
      expect(updatedClaim['status'], 'PENDING_OWNER');
      print('✅ 4. Manager Approved: Claim status advanced to PENDING_OWNER');
    });

    // 5. Manager Submits Own Claim (Bypass Verification)
    test('5. Client Test: Manager submits own claim -> routes directly to Owner', () async {
      expect(managerToken, isNotNull);
      final res = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $managerToken',
        },
        body: jsonEncode({
          'amount': 2200,
          'description': 'E2E Client Test - Manager Fuel & Inter-branch Travel',
          'categoryId': 'b87165b9-fc92-4444-8573-13240e421837',
          'location': 'Aligarh Nexa',
          'receiptUrl': 'https://devmotors-assets.s3.amazonaws.com/receipts/bill.png',
          'receiptFileName': 'fuel_bill.jpg',
        }),
      );
      expect(res.statusCode, anyOf([200, 201]));
      final body = jsonDecode(res.body);
      final expData = body['data'] ?? body;
      managerSelfExpenseId = expData['id'] ?? expData['_id'];
      expect(managerSelfExpenseId, isNotNull);

      // Verify that manager claims bypass manager queue and enter Owner queue
      expect(ClaimWorkflowEngine.isPendingForManager(expData['status'], expData), isFalse,
          reason: 'Manager claims must NEVER enter Manager review queue');
      expect(ClaimWorkflowEngine.isPendingForOwner(expData['status'], expData), isTrue,
          reason: 'Manager claims must route directly to Owner queue');
      print('✅ 5. Manager Claim Created: ID $managerSelfExpenseId directly routed to Owner (Bypass Active)');
    });

    // 6. Owner Login & Multi-Branch Review
    test('6. Client Test: Owner logs in and reviews both claims in Owner Queue', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': 'owner_dron',
          'password': defaultPassword,
        }),
      );
      expect(res.statusCode, 200, reason: 'Owner login must succeed');
      final data = jsonDecode(res.body)['data'];
      ownerToken = data['token'];
      ownerProfile = data['user'];
      expect(ownerToken, isNotNull);
      expect(ownerProfile?['role'], 'OWNER');

      // Fetch all claims for Owner
      final expRes = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: {'Authorization': 'Bearer $ownerToken'},
      );
      expect(expRes.statusCode, 200);
      final list = jsonDecode(expRes.body)['data'] as List;

      final empClaim = list.firstWhere((e) => e['id'] == testExpenseId, orElse: () => null);
      final mgrClaim = list.firstWhere((e) => e['id'] == managerSelfExpenseId, orElse: () => null);

      expect(empClaim, isNotNull);
      expect(mgrClaim, isNotNull);
      expect(ClaimWorkflowEngine.isPendingForOwner(empClaim['status'], empClaim), isTrue);
      expect(ClaimWorkflowEngine.isPendingForOwner(mgrClaim['status'], mgrClaim), isTrue);
      print('✅ 6. Owner Logged In: Both Employee & Manager claims present in Owner Review Queue');
    });

    // 7. Owner Approves Claims -> Forwards to Cashier
    test('7. Client Test: Owner approves claims -> moves to PENDING_CASHIER', () async {
      expect(ownerToken, isNotNull);

      // Approve Employee Claim
      final res1 = await http.post(
        Uri.parse('$baseUrl/expenses/$testExpenseId/approval'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $ownerToken',
        },
        body: jsonEncode({
          'action': 'APPROVED_2',
          'comments': 'Approved by Owner Drona Agarwal. Forward for Payout.',
        }),
      );
      expect(res1.statusCode, 200);

      // Approve Manager Claim
      final res2 = await http.post(
        Uri.parse('$baseUrl/expenses/$managerSelfExpenseId/approval'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $ownerToken',
        },
        body: jsonEncode({
          'action': 'APPROVED_2',
          'comments': 'Manager Travel Approved by Owner. Forward for Payout.',
        }),
      );
      expect(res2.statusCode, 200);

      // Verify status changed to PENDING_CASHIER
      final expRes = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: {'Authorization': 'Bearer $ownerToken'},
      );
      final list = jsonDecode(expRes.body)['data'] as List;
      final c1 = list.firstWhere((e) => e['id'] == testExpenseId);
      final c2 = list.firstWhere((e) => e['id'] == managerSelfExpenseId);
      expect(c1['status'], 'PENDING_CASHIER');
      expect(c2['status'], 'PENDING_CASHIER');
      print('✅ 7. Owner Approved: Both claims advanced to PENDING_CASHIER');
    });

    // 8. Cashier Logs In & Disburses Payment
    test('8. Client Test: Cashier logs in and marks claims as PAID / Disbursed', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': 'nexa_shivam_acc',
          'password': defaultPassword,
        }),
      );
      expect(res.statusCode, 200, reason: 'Cashier login must succeed');
      final data = jsonDecode(res.body)['data'];
      cashierToken = data['token'];
      cashierProfile = data['user'];
      expect(cashierToken, isNotNull);
      expect(cashierProfile?['role'], 'CASHIER');

      // Cashier Disburses Employee Claim
      final payRes1 = await http.post(
        Uri.parse('$baseUrl/expenses/$testExpenseId/approval'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cashierToken',
        },
        body: jsonEncode({
          'action': 'PAY',
          'comments': 'Paid via UPI Txn #UPI9281729381',
        }),
      );
      expect(payRes1.statusCode, 200);

      // Cashier Disburses Manager Claim
      final payRes2 = await http.post(
        Uri.parse('$baseUrl/expenses/$managerSelfExpenseId/approval'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cashierToken',
        },
        body: jsonEncode({
          'action': 'PAY',
          'comments': 'Paid via Cash Voucher #CV-8821',
        }),
      );
      expect(payRes2.statusCode, 200);

      // Verify status changed to PAID
      final expRes = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: {'Authorization': 'Bearer $cashierToken'},
      );
      final list = jsonDecode(expRes.body)['data'] as List;
      final c1 = list.firstWhere((e) => e['id'] == testExpenseId);
      final c2 = list.firstWhere((e) => e['id'] == managerSelfExpenseId);
      expect(c1['status'], 'PAID');
      expect(c2['status'], 'PAID');
      expect(ClaimWorkflowEngine.isSettledOrRejected(c1['status'], c1), isTrue);
      expect(ClaimWorkflowEngine.isSettledOrRejected(c2['status'], c2), isTrue);
      print('✅ 8. Cashier Disbursed: Both claims marked as PAID and moved to Settled History');
    });

    // 9. Employee Notification & Settled Tab Verification
    test('9. Client Test: Employee verifies Settled History & Disbursed Notification', () async {
      expect(employeeToken, isNotNull);
      final expRes = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: {'Authorization': 'Bearer $employeeToken'},
      );
      expect(expRes.statusCode, 200);
      final list = jsonDecode(expRes.body)['data'] as List;

      // Filter own claims
      final myClaims = list.where((e) => ClaimWorkflowEngine.isClaimCreatedByUser(e, employeeProfile)).toList();
      final settledClaims = myClaims.where((e) => ClaimWorkflowEngine.isSettledOrRejected(e['status'], e)).toList();

      final settledTestClaim = settledClaims.firstWhere(
        (e) => e['id'] == testExpenseId,
        orElse: () => null,
      );
      expect(settledTestClaim, isNotNull, reason: 'Claim must be in employee Settled tab');

      // Check notification generation
      final notifs = NotificationService.getNotificationsForRole(
        'EMPLOYEE',
        myClaims,
        currentUser: employeeProfile,
      );
      expect(notifs.any((n) => n['type'] == 'PAID'), isTrue, reason: 'Employee must receive Settled/Paid alert');
      print('✅ 9. Employee Verified: Claim present in Settled tab with settlement notification delivered');
    });

    // 10. Clean Up Test Data
    test('10. Clean Up: Delete test expenses from database', () async {
      if (testExpenseId != null && ownerToken != null) {
        await http.delete(
          Uri.parse('$baseUrl/expenses/$testExpenseId'),
          headers: {'Authorization': 'Bearer $ownerToken'},
        );
      }
      if (managerSelfExpenseId != null && ownerToken != null) {
        await http.delete(
          Uri.parse('$baseUrl/expenses/$managerSelfExpenseId'),
          headers: {'Authorization': 'Bearer $ownerToken'},
        );
      }
      print('✅ 10. Clean Up: Test claims cleanly deleted from database');
    });
  });
}
