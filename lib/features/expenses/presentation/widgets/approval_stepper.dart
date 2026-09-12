import 'package:flutter/material.dart';
import '../../../../core/utils/claim_workflow_engine.dart';
import '../../../../core/utils/safe_parser.dart';

class ApprovalStepper extends StatelessWidget {
  final String status;
  final String? rejectionReason;
  final String? creatorRole;
  final dynamic expense;

  const ApprovalStepper({
    super.key,
    required this.status,
    this.rejectionReason,
    this.creatorRole,
    this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase().trim();
    final isRejected = s.contains('REJECT');

    final expId = expense is Map ? SafeParser.getString(expense['id'] ?? expense['_id']) : '';
    final isOwnerApprovedInEngine = expId.isNotEmpty && ClaimWorkflowEngine.isOwnerApproved(expId);

    final effCreatorRole = (creatorRole != null && creatorRole!.isNotEmpty)
        ? creatorRole!.toUpperCase()
        : (expense != null ? ClaimWorkflowEngine.extractCreatorRole(expense) : 'EMPLOYEE');
    final isManagerClaim = effCreatorRole == 'MANAGER' || effCreatorRole == 'CASHIER';

    final isOwnerRejected = isRejected && (s.contains('OWNER') || s.contains('DIRECTOR') || isManagerClaim);
    final isManagerRejected = isRejected && !isOwnerRejected;

    int currentStep = 1;
    if (s.contains('PAID') || s.contains('DISBURSED') || s.contains('SETTLE')) {
      currentStep = 4;
    } else if (s.contains('PENDING_CASHIER') || s.contains('APPROVED_2') || s.contains('OWNER_APPROVED') || s.contains('APPROVED_OWNER') || isOwnerApprovedInEngine) {
      currentStep = 3;
    } else if (s.contains('PENDING_OWNER') || s.contains('APPROVED_1') || s.contains('MANAGER_APPROVED') || s == 'APPROVED' || s == 'LEVEL_2' || (isManagerClaim && !isRejected)) {
      currentStep = 2;
    } else if (isRejected) {
      currentStep = -1;
    } else {
      currentStep = 1; // PENDING_MANAGER or PENDING
    }

    Widget buildNode(String title, bool isCompleted, bool isCurrent, {bool isNodeRejected = false}) {
      Color circleColor = Colors.grey.shade200;
      Color textColor = Colors.grey.shade600;
      Widget content = Text(
        title.substring(0, 1),
        style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
      );

      if (isNodeRejected) {
        circleColor = const Color(0xFFEF4444);
        textColor = const Color(0xFFEF4444);
        content = const Icon(Icons.close, size: 13, color: Colors.white);
      } else if (isCompleted) {
        circleColor = const Color(0xFF10B981);
        textColor = const Color(0xFF10B981);
        content = const Icon(Icons.check, size: 13, color: Colors.white);
      } else if (isCurrent) {
        circleColor = const Color(0xFF2563EB);
        textColor = const Color(0xFF2563EB);
        content = Text(
          title.substring(0, 1),
          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              boxShadow: isCurrent
                  ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1)]
                  : isNodeRejected
                      ? [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1)]
                      : null,
            ),
            child: Center(child: content),
          ),
          const SizedBox(height: 4),
          Text(
            isNodeRejected ? "$title ✕" : title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent || isCompleted || isNodeRejected ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          )
        ],
      );
    }

    Widget buildLine(bool isPassed, {bool isLineRejected = false}) {
      Color lineColor = Colors.grey.shade300;
      if (isLineRejected) {
        lineColor = const Color(0xFFEF4444);
      } else if (isPassed) {
        lineColor = const Color(0xFF10B981);
      }

      return Expanded(
        child: Container(
          height: 3,
          margin: const EdgeInsets.only(bottom: 14),
          color: lineColor,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: () {
              if (effCreatorRole == 'MANAGER') {
                if (isRejected) {
                  return [
                    buildNode("1. Mgr", true, false),
                    buildLine(false, isLineRejected: true),
                    buildNode("2. Own", false, false, isNodeRejected: true),
                    buildLine(false),
                    buildNode("3. Paid", false, false),
                  ];
                }
                return [
                  buildNode("1. Mgr", true, false),
                  buildLine(true),
                  buildNode("2. Own", currentStep >= 3, currentStep == 2),
                  buildLine(currentStep >= 3),
                  buildNode("3. Paid", currentStep >= 4, currentStep == 3),
                ];
              } else if (effCreatorRole == 'CASHIER') {
                if (isRejected) {
                  return [
                    buildNode("1. Csh", true, false),
                    buildLine(false, isLineRejected: true),
                    buildNode("2. Own", false, false, isNodeRejected: true),
                    buildLine(false),
                    buildNode("3. Paid", false, false),
                  ];
                }
                return [
                  buildNode("1. Csh", true, false),
                  buildLine(true),
                  buildNode("2. Own", currentStep >= 3, currentStep == 2),
                  buildLine(currentStep >= 3),
                  buildNode("3. Paid", currentStep >= 4, currentStep == 3),
                ];
              } else if (effCreatorRole == 'OWNER') {
                if (isRejected) {
                  return [
                    buildNode("1. Own", true, false),
                    buildLine(false, isLineRejected: true),
                    buildNode("2. Paid", false, false, isNodeRejected: true),
                  ];
                }
                return [
                  buildNode("1. Own", true, false),
                  buildLine(currentStep >= 4),
                  buildNode("2. Paid", currentStep >= 4, currentStep < 4),
                ];
              } else {
                // EMPLOYEE (Default 4-step workflow)
                if (isRejected) {
                  return [
                    buildNode("1. Emp", true, false),
                    buildLine(false, isLineRejected: isManagerRejected),
                    buildNode("2. Mgr", isOwnerRejected, false, isNodeRejected: isManagerRejected),
                    buildLine(false, isLineRejected: isOwnerRejected),
                    buildNode("3. Own", false, false, isNodeRejected: isOwnerRejected),
                    buildLine(false),
                    buildNode("4. Paid", false, false),
                  ];
                }
                return [
                  buildNode("1. Emp", true, false),
                  buildLine(true),
                  buildNode("2. Mgr", currentStep >= 2, currentStep == 1),
                  buildLine(currentStep >= 2),
                  buildNode("3. Own", currentStep >= 3, currentStep == 2),
                  buildLine(currentStep >= 3),
                  buildNode("4. Paid", currentStep >= 4, currentStep == 3),
                ];
              }
            }(),
          ),
          if (isRejected) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xffFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xffFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel, color: Color(0xffDC2626), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rejectionReason != null && rejectionReason!.trim().isNotEmpty
                          ? "Rejected by ${isOwnerRejected ? "Owner" : "Manager"}: $rejectionReason"
                          : "Claim Rejected by ${isOwnerRejected ? "Owner" : "Manager"}: Policy criteria not met",
                      style: const TextStyle(
                        color: Color(0xffDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (currentStep == 2) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xffEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xffBFDBFE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top, color: Color(0xff2563EB), size: 12),
                  const SizedBox(width: 5),
                  Text(
                    isManagerClaim
                        ? (effCreatorRole == 'CASHIER'
                            ? "Cashier Claim • In Owner Review Queue"
                            : "Manager Claim • In Owner Review Queue")
                        : "Manager Approved • In Owner Review Queue",
                    style: const TextStyle(
                      color: Color(0xff2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (currentStep == 3) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xffECFDF5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xffA7F3D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xff059669), size: 12),
                  SizedBox(width: 5),
                  Text(
                    "Owner Approved • Forwarded to Cashier for Payout",
                    style: TextStyle(
                      color: Color(0xff059669),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (currentStep == 4) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xffECFDF5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xffA7F3D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all, color: Color(0xff059669), size: 12),
                  SizedBox(width: 5),
                  Text(
                    "Settled & Paid • Funds Disbursed",
                    style: TextStyle(
                      color: Color(0xff059669),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
