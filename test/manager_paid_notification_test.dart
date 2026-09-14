import 'package:flutter_test/flutter_test.dart';
import 'package:dev_motors/core/services/notification_service.dart';
import 'package:dev_motors/core/utils/claim_workflow_engine.dart';

void main() {
  test('verify manager claims and notification when paid', () {
    final user = {
      "id": "nexa_stephen_sm",
      "employeeId": "nexa_stephen_sm",
      "name": "St. Stephen Joseph",
      "role": "MANAGER",
      "locationId": "6d99340f-3db1-430a-98dd-dc306aae7049",
      "location": {
        "name": "Aligarh Nexa",
      }
    };

    final expenses = [
      {
        "id": "56db146e-1ff0-4962-b27c-22e5c9db6d02",
        "amount": 999,
        "description": "Testing final phase 2",
        "status": "PAID",
        "employeeId": "nexa_stephen_sm",
        "locationId": "6d99340f-3db1-430a-98dd-dc306aae7049",
        "location": {"name": "Aligarh Nexa"},
        "employee": {
          "id": "nexa_stephen_sm",
          "name": "St. Stephen Joseph",
          "employeeId": "nexa_stephen_sm",
          "role": "MANAGER"
        }
      }
    ];

    bool isClaimCreatedByMe(dynamic exp) => ClaimWorkflowEngine.isClaimCreatedByUser(exp, user);

    final myClaims = expenses.where((e) => isClaimCreatedByMe(e) && !ClaimWorkflowEngine.isSettledOrRejected(e["status"], e)).toList();
    final history = expenses.where((e) => isClaimCreatedByMe(e) && ClaimWorkflowEngine.isSettledOrRejected(e["status"], e)).toList();

    final notifs = NotificationService.getNotificationsForRole(
      "MANAGER",
      expenses,
      userBranch: "Aligarh Nexa",
      currentUser: user,
    );

    expect(myClaims.length, 0);
    expect(history.length, 1);
    expect(notifs.length, 1);
    expect(notifs.first['title'], 'Your Claim Settled');
  });
}
