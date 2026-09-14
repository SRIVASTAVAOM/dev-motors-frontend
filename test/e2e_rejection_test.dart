import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:dev_motors/core/utils/claim_workflow_engine.dart';
import 'package:dev_motors/core/services/notification_service.dart';

void main() {
  const baseUrl = 'https://dev-motors-backend.onrender.com/api';
  const defaultPassword = 'Dev@2026';

  test('Client Rejection Workflow: Employee submits -> Manager Rejects with Remarks -> Employee sees rejection', () async {
    // 1. Employee Login
    final empLogin = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'employeeId': 'nexa_muneesh_bsm', 'password': defaultPassword}),
    );
    expect(empLogin.statusCode, 200);
    final empToken = jsonDecode(empLogin.body)['data']['token'];
    final empProfile = jsonDecode(empLogin.body)['data']['user'];

    // 2. Employee creates claim
    final createRes = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $empToken'},
      body: jsonEncode({
        'amount': 950,
        'description': 'E2E Client Test - Disallowed personal expense',
        'categoryId': 'b87165b9-fc92-4444-8573-13240e421837',
        'location': 'Aligarh Nexa',
      }),
    );
    expect(createRes.statusCode, anyOf([200, 201]));
    final claim = jsonDecode(createRes.body)['data'] ?? jsonDecode(createRes.body);
    final claimId = claim['id'] ?? claim['_id'];
    expect(claimId, isNotNull);

    // 3. Manager logs in
    final mgrLogin = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'employeeId': 'nexa_stephen_sm', 'password': defaultPassword}),
    );
    expect(mgrLogin.statusCode, 200);
    final mgrToken = jsonDecode(mgrLogin.body)['data']['token'];

    // 4. Manager rejects with custom reason
    const rejectionReason = 'Personal expense not covered by company dealership policy';
    ClaimWorkflowEngine.setRejectionRemark(claimId, rejectionReason);

    final rejectRes = await http.post(
      Uri.parse('$baseUrl/expenses/$claimId/approval'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $mgrToken'},
      body: jsonEncode({
        'action': 'REJECT',
        'reason': rejectionReason,
        'comments': rejectionReason,
      }),
    );
    expect(rejectRes.statusCode, 200);

    // 5. Employee verifies rejected claim
    final fetchRes = await http.get(
      Uri.parse('$baseUrl/expenses'),
      headers: {'Authorization': 'Bearer $empToken'},
    );
    expect(fetchRes.statusCode, 200);
    final list = jsonDecode(fetchRes.body)['data'] as List;
    final rejectedClaim = list.firstWhere((e) => e['id'] == claimId);

    expect(rejectedClaim['status'], 'REJECTED');
    expect(ClaimWorkflowEngine.isSettledOrRejected(rejectedClaim['status'], rejectedClaim), isTrue);

    // Verify rejection remark retrieval
    final retrievedRemark = ClaimWorkflowEngine.getRejectionRemark(claimId, rejectedClaim);
    expect(retrievedRemark, contains('Personal expense not covered'));

    // Verify rejection notification
    final notifs = NotificationService.getNotificationsForRole(
      'EMPLOYEE',
      [rejectedClaim],
      currentUser: empProfile,
    );
    expect(notifs.any((n) => n['type'] == 'REJECTED'), isTrue);

    // 6. Clean up
    await http.delete(
      Uri.parse('$baseUrl/expenses/$claimId'),
      headers: {'Authorization': 'Bearer $mgrToken'},
    );
  });
}
