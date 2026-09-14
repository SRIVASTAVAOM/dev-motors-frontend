import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/add_staff_dialog.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/edit_expense_dialog.dart';
import '../widgets/floating_pill_nav_bar.dart';
import '../../../profile/presentation/widgets/profile_sheet.dart';
import '../../../expenses/presentation/widgets/approval_stepper.dart';
import '../../../expenses/presentation/widgets/receipt_viewer_dialog.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../../core/utils/claim_workflow_engine.dart';
import '../../../../core/services/csv_export_service.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _navIndex = 0;
  int _selectedTab = 0;
  bool _isLoading = true;
  List<dynamic> _expenses = [];
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _getString(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    if (val is String) return val;
    if (val is Map) return val['name']?.toString() ?? val['status']?.toString() ?? fallback;
    return val.toString();
  }

  double _getDouble(dynamic val) => double.tryParse(val?.toString() ?? '0') ?? 0.0;

  List<Map<String, dynamic>> _serverNotifs = [];

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getExpenses();
      _profile = ApiService.currentUser;
      _serverNotifs = await ApiService.getNotifications();

      setState(() {
        _expenses = List<dynamic>.from(list);
      });
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processApproval(String id, String action, {double? finalAmt, String? reason}) async {
    if (id.isEmpty) return;
    if (action.toUpperCase().contains('REJECT') && reason != null && reason.isNotEmpty) {
      ClaimWorkflowEngine.setRejectionRemark(id, reason);
    }
    if (action.toUpperCase().contains('APPROVE')) {
      ClaimWorkflowEngine.markOwnerApproved(id);
    }
    await ApiService.processApproval(
      expenseId: id,
      action: action == 'APPROVE' ? 'APPROVED_2' : action,
      approvedAmount: finalAmt,
      comments: reason,
      remarks: reason,
    );
    if (mounted) {
      final isApprove = action.toUpperCase().contains('APPROVE');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isApprove ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isApprove
                      ? "Claim approved & forwarded for payout!"
                      : "Claim rejected and employee notified.",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: isApprove ? const Color(0xff10B981) : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    _loadData();
  }

  void _showRejectDialog(String id) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text("Reject Expense Claim", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please state the business reason for rejecting this claim. The employee will be notified immediately.",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Enter rejection reason (e.g. invalid bill date, exceeds policy limit...)",
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xffF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xffCBD5E1)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please provide a reason for rejection")),
                );
                return;
              }
              Navigator.pop(ctx);
              _processApproval(id, 'REJECTED', reason: reason);
            },
            child: const Text("Confirm Rejection", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(String id) async {
    final ok = await ApiService.deleteExpense(id);
    if (ok) {
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Claim deleted!")));
    }
  }

  List<dynamic> get _reviewQueue => _expenses.where((e) {
    if (e is! Map) return false;
    final status = e['status'];
    return ClaimWorkflowEngine.isPendingForOwner(status, e);
  }).toList();

  List<dynamic> get _allClaims => _expenses;

  @override
  Widget build(BuildContext context) {
    if (_navIndex == 1) {
      return ReportsPage(onBack: () => setState(() => _navIndex = 0));
    }

    final notifs = NotificationService.getNotificationsForRole(
      'OWNER',
      _expenses,
      userBranch: _profile?['branch'],
      currentUser: _profile ?? ApiService.currentUser,
      serverNotifications: _serverNotifs,
    );
    final currentList = _selectedTab == 0 ? _reviewQueue : _allClaims;

    final userName = _getString(_profile?['name'], "Dev Motors");
    final userOccupation = _getString(_profile?['designation'], "Managing Director / Owner");
    final userBranch = _getString(_profile?['branch'], "All Dealerships Oversight");

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xffFEF3C7),
                      child: Icon(Icons.shield, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xff0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xffFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xffFDE68A), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.workspace_premium, size: 11, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(
                                      userOccupation,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xffF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xffE2E8F0), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.business_outlined, size: 11, color: Color(0xff64748B)),
                                    const SizedBox(width: 3),
                                    Text(
                                      userBranch,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xff475569),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          tooltip: "Notifications",
                          icon: const Icon(Icons.notifications_none, color: Colors.grey),
                          onPressed: () => NotificationService.showNotificationSheet(
                            context,
                            'OWNER',
                            _expenses,
                            () => setState(() {}),
                            currentUser: _profile ?? ApiService.currentUser,
                            userBranch: userBranch,
                            serverNotifications: _serverNotifs,
                          ),
                        ),
                        if (notifs.isNotEmpty)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text("${notifs.length}", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Color(0xff64748B)),
                      tooltip: "More Options",
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) async {
                        if (val == 'add_staff') {
                          showDialog(
                            context: context,
                            builder: (_) => AddStaffDialog(onStaffCreated: _loadData),
                          );
                        } else if (val == 'export_csv') {
                          final ok = await CsvExportService.exportExpensesToCsv(
                            _expenses,
                            filenamePrefix: 'dev_motors_company_ledger',
                            branch: 'All Branches',
                          );
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Company ledger exported as CSV!"),
                                backgroundColor: Color(0xff10B981),
                              ),
                            );
                          }
                        } else if (val == 'change_password') {
                          showDialog(
                            context: context,
                            builder: (_) => const ChangePasswordDialog(),
                          );
                        } else if (val == 'refresh') {
                          _loadData();
                        } else if (val == 'profile') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const ProfileSheet(),
                          );
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'add_staff',
                          child: Row(
                            children: [
                              Icon(Icons.person_add_alt_1, color: Color(0xff2563EB), size: 18),
                              SizedBox(width: 10),
                              Expanded(child: Text('Add New Staff', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export_csv',
                          child: Row(
                            children: [
                              Icon(Icons.download, color: Color(0xffEA580C), size: 18),
                              SizedBox(width: 10),
                              Expanded(child: Text('Export Ledger (CSV)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'change_password',
                          child: Row(
                            children: [
                              Icon(Icons.vpn_key_outlined, color: Color(0xff64748B), size: 18),
                              SizedBox(width: 10),
                              Expanded(child: Text('Change Password', style: TextStyle(fontSize: 13))),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'refresh',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, color: Color(0xff64748B), size: 18),
                              SizedBox(width: 10),
                              Expanded(child: Text('Refresh Data', style: TextStyle(fontSize: 13))),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, color: Color(0xff64748B), size: 18),
                              SizedBox(width: 10),
                              Expanded(child: Text('My Profile', style: TextStyle(fontSize: 13))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2-Tab Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTab == 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.pending_actions, size: 16, color: Colors.orange),
                                const SizedBox(width: 6),
                                Text(
                                  "Action Needed (${_reviewQueue.length})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedTab == 0 ? Colors.orange : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTab == 1 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.view_agenda_outlined, size: 16, color: Color(0xff2563EB)),
                                const SizedBox(width: 6),
                                Text(
                                  "All Branches (${_allClaims.length})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedTab == 1 ? const Color(0xff2563EB) : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (currentList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _selectedTab == 0 ? "No claims waiting for owner clearance" : "No claims in system",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, idx) {
                      final exp = currentList[idx] is Map ? currentList[idx] : {};
                      final statusStr = _getString(exp['status'], 'PENDING');
                      final id = _getString(exp['id']).isNotEmpty ? _getString(exp['id']) : _getString(exp['_id']);

                      final receiptData = (exp['receiptImage'] ?? exp['receiptUrl'] ?? '').toString();
                      final hasReceipt = receiptData.trim().isNotEmpty && receiptData != 'null';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xffEFF6FF), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.receipt, color: Color(0xff2563EB), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_getString(exp['description'], 'Expense Claim'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${_getString(exp['employeeName'], 'Staff')} • ${_getString(exp['location'], 'Dealership')}",
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Text("₹${_getDouble(exp['amount']).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1E293B))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ApprovalStepper(
                              status: statusStr,
                              rejectionReason: ClaimWorkflowEngine.getRejectionRemark(id, exp),
                              creatorRole: ClaimWorkflowEngine.extractCreatorRole(exp),
                              expense: exp,
                            ),

                            if (hasReceipt) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => ReceiptViewerDialog(
                                    receiptData: receiptData,
                                    title: _getString(exp['description'], 'Expense Bill'),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xffBFDBFE)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.attachment_rounded, size: 15, color: Color(0xff2563EB)),
                                      SizedBox(width: 5),
                                      Text(
                                        "View Attached Receipt / Bill",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff2563EB)),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.open_in_new, size: 13, color: Color(0xff2563EB)),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // OWNER EDIT & DELETE BUTTONS
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => EditExpenseDialog(expense: exp, onUpdated: _loadData),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: const Color(0xffEFF6FF), borderRadius: BorderRadius.circular(8)),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit, size: 14, color: Color(0xff2563EB)),
                                        SizedBox(width: 4),
                                        Text("Edit Claim", style: TextStyle(fontSize: 12, color: Color(0xff2563EB), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _deleteExpense(id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: const Color(0xffFEE2E2), borderRadius: BorderRadius.circular(8)),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                        SizedBox(width: 4),
                                        Text("Delete", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (!ClaimWorkflowEngine.isSettledOrRejected(statusStr) && !ClaimWorkflowEngine.isPendingForCashier(statusStr, exp)) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _showRejectDialog(id),
                                      child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _processApproval(id, 'APPROVE'),
                                      child: const Text("Approve for Cashier", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (ClaimWorkflowEngine.isPendingForCashier(statusStr, exp)) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xffEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xffBFDBFE)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 16, color: Color(0xff2563EB)),
                                    SizedBox(width: 6),
                                    Text(
                                      "Approved — Forwarded to Cashier for Payout",
                                      style: TextStyle(color: Color(0xff2563EB), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (statusStr.toUpperCase() == 'PAID' || statusStr.toUpperCase().contains('SETTLE')) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xffDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xff86EFAC)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 16, color: Color(0xff16A34A)),
                                    SizedBox(width: 6),
                                    Text(
                                      "Disbursed / Paid (Settled)",
                                      style: TextStyle(color: Color(0xff16A34A), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Expense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => showDialog(context: context, builder: (_) => AddExpenseDialog(onCreated: _loadData)),
      ),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _navIndex,
        items: const [
          FloatingPillNavItem(icon: Icons.shield, label: 'Oversight'),
          FloatingPillNavItem(icon: Icons.bar_chart, label: 'Reports'),
          FloatingPillNavItem(icon: Icons.person, label: 'Profile'),
        ],
        onTap: (idx) {
          if (idx == 2) {
            showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const ProfileSheet());
          } else {
            setState(() => _navIndex = idx);
          }
        },
      ),
    );
  }
}
