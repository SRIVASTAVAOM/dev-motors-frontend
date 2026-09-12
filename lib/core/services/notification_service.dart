import 'package:flutter/material.dart';
import '../utils/safe_parser.dart';
import '../utils/claim_workflow_engine.dart';
import 'api_service.dart';

class NotificationService {
  static final Map<String, Set<String>> _dismissedByRole = {
    'EMPLOYEE': {},
    'MANAGER': {},
    'OWNER': {},
    'CASHIER': {},
  };

  static List<Map<String, dynamic>> getNotificationsForRole(
    String role,
    List<dynamic> expenses, {
    dynamic userBranch,
    Map<String, dynamic>? currentUser,
  }) {
    final List<Map<String, dynamic>> alerts = [];
    final r = role.toUpperCase();
    final dismissed = _dismissedByRole[r] ?? {};

    final effectiveUser = currentUser ?? ApiService.currentUser;
    final effectiveBranch = userBranch ??
        (effectiveUser?['location'] is Map ? effectiveUser!['location']['name'] : effectiveUser?['location']) ??
        effectiveUser?['branch'];

    for (var exp in expenses) {
      if (exp is! Map) continue;
      final rawStatus = exp['status'];
      final status = SafeParser.getString(
        rawStatus is Map ? (rawStatus['name'] ?? rawStatus['status']) : rawStatus,
        'PENDING',
      ).toUpperCase().trim();

      final id = SafeParser.getString(exp['id'] ?? exp['_id'], 'EXP');

      // Skip if cleared / dismissed
      if (dismissed.contains(id)) continue;

      final title = SafeParser.getString(exp['title'] ?? exp['description'], 'Expense Claim');
      final amount = SafeParser.getDouble(exp['amount']).toStringAsFixed(0);
      final empName = SafeParser.getString(
        exp['employee'] is Map
            ? (exp['employee']['name'] ?? exp['employee']['employeeId'])
            : (exp['employeeName'] ?? exp['userName'] ?? exp['employee']),
        'Employee',
      );

      final rawBranch = exp['branch'] ??
          exp['branchName'] ??
          (exp['location'] is Map ? exp['location']['name'] : exp['location']) ??
          (exp['employee'] is Map
              ? (exp['employee']['branch'] ??
                  (exp['employee']['location'] is Map
                      ? exp['employee']['location']['name']
                      : exp['employee']['location']))
              : null);
      final branch = SafeParser.getString(rawBranch, '');

      final creatorRole = ClaimWorkflowEngine.extractCreatorRole(exp);
      final isMyClaim = effectiveUser != null && ClaimWorkflowEngine.isClaimCreatedByUser(exp, effectiveUser);

      if (r == 'MANAGER') {
        if (isMyClaim || creatorRole == 'MANAGER') {
          // Notifications for manager's OWN claims
          if (status.contains('REJECT')) {
            final reason = ClaimWorkflowEngine.getRejectionRemark(id, exp);
            alerts.add({
              'id': '${id}_mgr_own_rej',
              'title': 'Your Claim Rejected by Owner',
              'message': 'Your claim of ₹$amount was rejected by Owner: $reason',
              'type': 'REJECTED',
              'unread': true,
              'time': 'Rejected',
              'expenseId': id,
            });
          } else if (ClaimWorkflowEngine.isPendingForCashier(status, exp)) {
            alerts.add({
              'id': '${id}_mgr_own_appr',
              'title': 'Your Claim Approved by Owner',
              'message': 'Your claim of ₹$amount for "$title" was approved by Owner & forwarded for payout.',
              'type': 'APPROVED',
              'unread': true,
              'time': 'Approved for Payout',
              'expenseId': id,
            });
          } else if (status == 'PAID' || status.contains('SETTLE') || status.contains('DISBURSE') || ClaimWorkflowEngine.isCashierPaid(id)) {
            alerts.add({
              'id': '${id}_mgr_own_paid',
              'title': 'Your Claim Settled',
              'message': 'Your claim of ₹$amount has been disbursed/settled by Cashier.',
              'type': 'PAID',
              'unread': true,
              'time': 'Settled',
              'expenseId': id,
            });
          }
        } else {
          // Strictly exclude claims created by OWNER or CASHIER - managers never review them!
          if (creatorRole == 'OWNER' || creatorRole == 'CASHIER') continue;

          // Branch gating: only notify for claims matching the manager's branch
          if (effectiveBranch != null && !ClaimWorkflowEngine.matchesBranch(userBranch: effectiveBranch, expenseBranch: branch, currentUser: effectiveUser)) {
            continue;
          }

          // Notifications for other employees' claims in manager queue
          if (ClaimWorkflowEngine.isPendingForManager(status, exp)) {
            alerts.add({
              'id': id,
              'title': 'New Claim: $empName',
              'message': '₹$amount for "$title"${branch.isNotEmpty ? " ($branch)" : ""} awaits your review.',
              'type': 'PENDING_APPROVAL',
              'unread': true,
              'time': 'Needs Action',
              'expenseId': id,
            });
          } else if (status == 'PENDING_OWNER' || status == 'APPROVED_1' || status.contains('MANAGER_APPROVED')) {
            alerts.add({
              'id': '${id}_mgr_fwd',
              'title': 'Claim Forwarded: $empName',
              'message': '₹$amount for "$title" forwarded to Owner for final approval.',
              'type': 'APPROVED',
              'unread': false,
              'time': 'In Owner Review',
              'expenseId': id,
            });
          } else if (ClaimWorkflowEngine.isPendingForCashier(status, exp)) {
            alerts.add({
              'id': '${id}_mgr_owner_appr',
              'title': 'Claim Approved by Owner: $empName',
              'message': '₹$amount for "$title" approved by Owner & sent to Cashier for payout.',
              'type': 'APPROVED',
              'unread': false,
              'time': 'Ready for Payout',
              'expenseId': id,
            });
          } else if (status == 'PAID' || status.contains('SETTLE') || status.contains('DISBURSE') || ClaimWorkflowEngine.isCashierPaid(id)) {
            alerts.add({
              'id': '${id}_mgr_disbursed',
              'title': 'Claim Disbursed: $empName',
              'message': '₹$amount for "$title"${branch.isNotEmpty ? " ($branch)" : ""} has been disbursed by Cashier.',
              'type': 'PAID',
              'unread': true,
              'time': 'Disbursed',
              'expenseId': id,
            });
          }
        }
      } else if (r == 'OWNER') {
        if (ClaimWorkflowEngine.isPendingForOwner(status, exp)) {
          if (creatorRole == 'MANAGER') {
            alerts.add({
              'id': id,
              'title': 'Manager Raised Claim: $empName',
              'message': 'Manager raised ₹$amount for "$title"${branch.isNotEmpty ? " ($branch)" : ""}. Awaits your direct approval.',
              'type': 'PENDING_OWNER',
              'unread': true,
              'time': 'Manager Claim',
              'expenseId': id,
            });
          } else if (creatorRole == 'CASHIER') {
            alerts.add({
              'id': id,
              'title': 'Cashier Raised Claim: $empName',
              'message': 'Cashier raised ₹$amount for "$title"${branch.isNotEmpty ? " ($branch)" : ""}. Awaits your direct sign-off.',
              'type': 'PENDING_OWNER',
              'unread': true,
              'time': 'Cashier Claim',
              'expenseId': id,
            });
          } else {
            alerts.add({
              'id': id,
              'title': 'Owner Approval: $empName',
              'message': '₹$amount for "$title"${branch.isNotEmpty ? " ($branch)" : ""} awaits your final sign-off.',
              'type': 'PENDING_OWNER',
              'unread': true,
              'time': 'Pending Final',
              'expenseId': id,
            });
          }
        } else if (status == 'PAID' || status.contains('SETTLE') || status.contains('DISBURSE') || ClaimWorkflowEngine.isCashierPaid(id)) {
          alerts.add({
            'id': '${id}_owner_paid',
            'title': 'Payout Complete: $empName',
            'message': 'Cashier disbursed ₹$amount for "$title"${branch.isNotEmpty ? " ($branch)" : ""}. Claim successfully settled.',
            'type': 'PAID',
            'unread': true,
            'time': 'Settled',
            'expenseId': id,
          });
        }
      } else if (r == 'CASHIER') {
        if (isMyClaim || creatorRole == 'CASHIER') {
          if (status.contains('REJECT')) {
            final reason = ClaimWorkflowEngine.getRejectionRemark(id, exp);
            alerts.add({
              'id': '${id}_csh_own_rej',
              'title': 'Your Claim Rejected',
              'message': 'Your claim ₹$amount was rejected by Owner: $reason',
              'type': 'REJECTED',
              'unread': true,
              'time': 'Rejected',
              'expenseId': id,
            });
          } else if (ClaimWorkflowEngine.isPendingForCashier(status, exp)) {
            alerts.add({
              'id': '${id}_csh_own_ready',
              'title': 'Your Claim Approved by Owner',
              'message': 'Your claim ₹$amount for "$title" was approved by Owner & ready for cash disbursal.',
              'type': 'READY_PAYMENT',
              'unread': true,
              'time': 'Ready for Disbursal',
              'expenseId': id,
            });
          } else if (status == 'PAID' || status.contains('SETTLE') || status.contains('DISBURSE') || ClaimWorkflowEngine.isCashierPaid(id)) {
            alerts.add({
              'id': '${id}_csh_own_paid',
              'title': 'Your Claim Settled',
              'message': 'Your claim of ₹$amount has been settled.',
              'type': 'PAID',
              'unread': true,
              'time': 'Settled',
              'expenseId': id,
            });
          }
        } else {
          if (ClaimWorkflowEngine.isPendingForCashier(status, exp)) {
            // Match branch if cashier has branch assigned and is not central/senior
            final isSenior = ClaimWorkflowEngine.isSeniorCashier(effectiveUser);
            if (!isSenior && effectiveBranch != null && !ClaimWorkflowEngine.matchesBranch(userBranch: effectiveBranch, expenseBranch: branch, currentUser: effectiveUser)) {
              continue;
            }
            alerts.add({
              'id': id,
              'title': 'Ready for Payout',
              'message': '₹$amount for $empName${branch.isNotEmpty ? " ($branch)" : ""} has been approved by Owner. Ready for cash disbursal.',
              'type': 'READY_PAYMENT',
              'unread': true,
              'time': 'Disbursal Ready',
              'expenseId': id,
            });
          }
        }
      } else if (r == 'EMPLOYEE') {
        // Employees only receive notifications for their OWN claims
        if (effectiveUser != null && !isMyClaim) continue;

        if (status.contains('REJECT')) {
          final reason = ClaimWorkflowEngine.getRejectionRemark(id, exp);
          alerts.add({
            'id': '${id}_emp_rej',
            'title': 'Claim Rejected',
            'message': 'Claim ₹$amount was Rejected: $reason',
            'type': 'REJECTED',
            'unread': true,
            'time': 'Rejected',
            'expenseId': id,
          });
        } else if (status == 'PAID' || status.contains('SETTLE') || status.contains('DISBURSE') || ClaimWorkflowEngine.isCashierPaid(id)) {
          alerts.add({
            'id': '${id}_emp_paid',
            'title': 'Claim Disbursed & Settled 🎉',
            'message': 'Your claim of ₹$amount for "$title" has been disbursed by Cashier.',
            'type': 'PAID',
            'unread': true,
            'time': 'Disbursed',
            'expenseId': id,
          });
        } else if (ClaimWorkflowEngine.isPendingForCashier(status, exp)) {
          alerts.add({
            'id': '${id}_emp_owner_appr',
            'title': 'Claim Approved by Owner',
            'message': 'Your claim of ₹$amount for "$title" was approved by Owner and sent to Cashier for payment disbursal.',
            'type': 'APPROVED',
            'unread': true,
            'time': 'Approved for Payout',
            'expenseId': id,
          });
        } else if (status == 'PENDING_OWNER' || status == 'APPROVED_1' || status.contains('MANAGER_APPROVED') || status.contains('APPROVED')) {
          alerts.add({
            'id': '${id}_emp_mgr_appr',
            'title': 'Claim Approved by Manager',
            'message': 'Your claim of ₹$amount for "$title" was approved by Manager and forwarded to Owner for final approval.',
            'type': 'APPROVED',
            'unread': true,
            'time': 'In Owner Review',
            'expenseId': id,
          });
        }
      }
    }
    return alerts;
  }

  static void dismissNotification(String role, String notifId) {
    final r = role.toUpperCase();
    _dismissedByRole.putIfAbsent(r, () => <String>{});
    _dismissedByRole[r]!.add(notifId);
  }

  static void clearAllForRole(
    String role,
    List<dynamic> expenses, {
    Map<String, dynamic>? currentUser,
    dynamic userBranch,
  }) {
    final r = role.toUpperCase();
    final current = getNotificationsForRole(
      r,
      expenses,
      currentUser: currentUser,
      userBranch: userBranch,
    );
    _dismissedByRole.putIfAbsent(r, () => <String>{});
    for (var n in current) {
      _dismissedByRole[r]!.add(n['id'].toString());
    }
  }

  static void showNotificationSheet(
    BuildContext context,
    String role,
    List<dynamic> expenses,
    VoidCallback onRefresh, {
    Map<String, dynamic>? currentUser,
    dynamic userBranch,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final notifs = getNotificationsForRole(
              role,
              expenses,
              currentUser: currentUser,
              userBranch: userBranch,
            );

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxHeight: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Color(0xff2563EB), size: 22),
                          const SizedBox(width: 8),
                          Text("Notifications ($role)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      if (notifs.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            clearAllForRole(role, expenses);
                            setModalState(() {});
                            onRefresh();
                          },
                          child: const Text("Clear All", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const Divider(),
                  if (notifs.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text("No new notifications", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: notifs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final n = notifs[index];
                          final isReject = n['type'] == 'REJECTED';
                          final isPaid = n['type'] == 'PAID';

                          Color badgeColor = const Color(0xff2563EB);
                          if (isReject) badgeColor = Colors.red;
                          if (isPaid) badgeColor = Colors.green;

                          return Dismissible(
                            key: Key(n['id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: Colors.red.shade100,
                              child: const Icon(Icons.delete, color: Colors.red),
                            ),
                            onDismissed: (_) {
                              dismissNotification(role, n['id'].toString());
                              setModalState(() {});
                              onRefresh();
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              leading: CircleAvatar(
                                backgroundColor: badgeColor.withValues(alpha: 0.1),
                                child: Icon(
                                  isReject ? Icons.cancel : (isPaid ? Icons.check_circle : Icons.receipt_long),
                                  color: badgeColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(n['message'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              trailing: Text(n['time'] ?? '', style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
