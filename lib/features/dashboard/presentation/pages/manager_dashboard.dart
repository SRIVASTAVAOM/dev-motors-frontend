import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/claim_workflow_engine.dart';
import '../../../../core/utils/safe_parser.dart';
import '../../../expenses/presentation/widgets/approval_stepper.dart';
import '../../../expenses/presentation/widgets/receipt_viewer_dialog.dart';
import '../../../profile/presentation/widgets/profile_sheet.dart';
import '../../../profile/presentation/widgets/change_password_dialog.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../reports/presentation/pages/reports_page.dart';

import '../widgets/add_expense_dialog.dart';
import '../widgets/edit_expense_dialog.dart';
import '../widgets/floating_pill_nav_bar.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _navIndex = 0;
  int _selectedTab = 0;
  bool _isLoading = true;
  bool _showAllBranches = false;
  List<dynamic> _expenses = [];
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _serverNotifs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _getString(dynamic val, [String fallback = '']) => SafeParser.getString(val, fallback);

  double _getDouble(dynamic val) => SafeParser.getDouble(val);

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


  Future<void> _processApproval(String id, String action, {String? reason}) async {
    if (id.isEmpty) return;
    if (action.toUpperCase().contains('REJECT') && reason != null && reason.isNotEmpty) {
      ClaimWorkflowEngine.setRejectionRemark(id, reason);
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.processApproval(
        expenseId: id,
        action: action == 'APPROVE' ? 'APPROVED_1' : action,
        remarks: reason,
        comments: reason,
      );
      if (mounted) {
        final isApprove = action.toUpperCase().contains('APPROVE') || action.toUpperCase().contains('ACCEPT');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(isApprove ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isApprove
                        ? "Claim approved and forwarded to Owner!"
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
    await _loadData();
    if (mounted) setState(() => _isLoading = false);
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
            Text("Reject Claim", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Specify why this claim is being rejected:", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "e.g. Bill invalid / Policy criteria not met",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              _processApproval(id, 'REJECT', reason: reason.isNotEmpty ? reason : 'Policy criteria not met');
            },
            child: const Text("Confirm Reject"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(String id) async {
    final ok = await ApiService.deleteExpense(id);
    if (ok) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Claim deleted!")));
      }
    }
  }

  bool _isClaimCreatedByMe(dynamic exp) {
    return ClaimWorkflowEngine.isClaimCreatedByUser(exp, _profile ?? ApiService.currentUser);
  }

  dynamic get _currentMgrBranch =>
      _profile?['location'] ??
      _profile?['branch'] ??
      _profile?['branchName'] ??
      ApiService.currentUser?['location'] ??
      ApiService.currentUser?['branch'];

  List<dynamic> get _allPendingClaims => _expenses.where((e) {
    if (e is! Map) return false;
    if (_isClaimCreatedByMe(e)) return false; // Self-created claims never enter Manager review queue!
    final status = e['status'];
    return ClaimWorkflowEngine.isPendingForManager(status, e);
  }).toList();

  List<dynamic> get _actionNeededList {
    final mgrBranch = _currentMgrBranch;
    final pending = _allPendingClaims;

    if (_showAllBranches) return pending;

    final branchFiltered = pending.where((e) {
      final expBranch = e['branch'] ??
          e['branchName'] ??
          (e['location'] is Map ? e['location']['name'] : e['location']) ??
          (e['employee'] is Map ? e['employee']['branch'] : null) ??
          (e['employee'] is Map
              ? (e['employee']['location'] is Map ? e['employee']['location']['name'] : e['employee']['location'])
              : null);

      return ClaimWorkflowEngine.matchesBranch(
        userBranch: mgrBranch,
        expenseBranch: expBranch,
      );
    }).toList();

    return branchFiltered;
  }

  List<dynamic> get _myClaimsList => _expenses.where((e) {
    if (e is! Map) return false;
    return _isClaimCreatedByMe(e) && !ClaimWorkflowEngine.isSettledOrRejected(e['status'], e);
  }).toList();

  List<dynamic> get _historyList {
    final mgrBranch = _currentMgrBranch;
    return _expenses.where((e) {
      if (e is! Map) return false;
      if (_isClaimCreatedByMe(e)) {
        return ClaimWorkflowEngine.isSettledOrRejected(e['status'], e);
      }
      if (!_showAllBranches) {
        final expBranch = e['branch'] ??
            e['branchName'] ??
            (e['location'] is Map ? e['location']['name'] : e['location']) ??
            (e['employee'] is Map ? e['employee']['branch'] : null) ??
            (e['employee'] is Map
                ? (e['employee']['location'] is Map ? e['employee']['location']['name'] : e['employee']['location'])
                : null);

        if (!ClaimWorkflowEngine.matchesBranch(
          userBranch: mgrBranch,
          expenseBranch: expBranch,
        )) {
          return false;
        }
      }
      final status = e['status'];
      return !ClaimWorkflowEngine.isPendingForManager(status, e);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_navIndex == 1) {
      return ReportsPage(onBack: () => setState(() => _navIndex = 0));
    }

    final notifs = NotificationService.getNotificationsForRole(
      'MANAGER',
      _expenses,
      userBranch: _currentMgrBranch,
      currentUser: _profile ?? ApiService.currentUser,
      serverNotifications: _serverNotifs,
    );
    List<dynamic> currentList;
    if (_selectedTab == 0) {
      currentList = _actionNeededList;
    } else if (_selectedTab == 1) {
      currentList = _myClaimsList;
    } else {
      currentList = _historyList;
    }

    final userName = _getString(_profile?['name'], "Branch Manager");
    final userOccupation = _getString(_profile?['designation'], "Branch Manager");
    final userBranch = _getString(_currentMgrBranch, "Main Outlet");

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
                      backgroundColor: Color(0xffEFF6FF),
                      child: Icon(Icons.manage_accounts, color: Color(0xff2563EB), size: 24),
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
                                  color: const Color(0xffEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xffBFDBFE), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.business_center_outlined, size: 11, color: Color(0xff2563EB)),
                                    const SizedBox(width: 4),
                                    Text(
                                      userOccupation,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xff2563EB),
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
                                    const Icon(Icons.location_on_outlined, size: 11, color: Color(0xff64748B)),
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
                            'MANAGER',
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
                        if (val == 'new_claim') {
                          showDialog(
                            context: context,
                            builder: (_) => AddExpenseDialog(onCreated: _loadData),
                          );
                        } else if (val == 'export_csv') {
                          final ok = await CsvExportService.exportExpensesToCsv(
                            _expenses,
                            filenamePrefix: 'dev_motors_${userBranch.replaceAll(" ", "_").toLowerCase()}_ledger',
                            branch: userBranch,
                          );
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("$userBranch ledger exported as CSV!"),
                                backgroundColor: const Color(0xff10B981),
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
                          value: 'new_claim',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, color: Color(0xff2563EB), size: 18),
                              SizedBox(width: 10),
                              Expanded(child: Text('Submit Own Claim', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export_csv',
                          child: Row(
                            children: [
                              Icon(Icons.download, color: Color(0xffEA580C), size: 18),
                              SizedBox(width: 10),
                              Expanded(child: Text('Export Branch CSV', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
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

                const SizedBox(height: 20),

                // 3-Tab Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      _tabItem(0, "Action (${_actionNeededList.length})", Icons.pending_actions),
                      _tabItem(1, "My Claims (${_myClaimsList.length})", Icons.person_pin),
                      _tabItem(2, "History (${_historyList.length})", Icons.history),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_selectedTab == 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showAllBranches ? "Showing: All Dealerships" : "Branch: $userBranch",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                      InkWell(
                        onTap: () => setState(() => _showAllBranches = !_showAllBranches),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _showAllBranches ? const Color(0xffEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _showAllBranches ? const Color(0xff2563EB) : Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune, size: 12, color: _showAllBranches ? const Color(0xff2563EB) : Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                _showAllBranches ? "My Branch Only" : "All Branches (${_allPendingClaims.length})",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _showAllBranches ? const Color(0xff2563EB) : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

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
                            _selectedTab == 0
                                ? (_showAllBranches
                                    ? "No pending claims across any dealership"
                                    : "No pending claims for $userBranch")
                                : (_selectedTab == 1 ? "You haven't submitted any claims" : "No history logs yet"),
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                          if (_selectedTab == 0 && !_showAllBranches && _allPendingClaims.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              "There are ${_allPendingClaims.length} pending claims at other locations.",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              icon: const Icon(Icons.visibility, size: 16),
                              label: Text("Review All Dealership Claims (${_allPendingClaims.length})"),
                              onPressed: () => setState(() => _showAllBranches = true),
                            ),
                          ],
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

                            final receiptData = (exp['receiptImage'] ?? exp['receiptUrl'] ?? '').toString();
                            final hasReceipt = receiptData.trim().isNotEmpty && receiptData != 'null';

                      final id = _getString(exp['id']).isNotEmpty ? _getString(exp['id']) : _getString(exp['_id']);
                      final isOwnClaim = _isClaimCreatedByMe(exp);
                      final canEditOwn = isOwnClaim && !statusStr.toUpperCase().contains('PAID');

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
                                        "${isOwnClaim ? 'My Expense' : _getString(exp['employee'] is Map ? exp['employee']['name'] : (exp['employeeName'] ?? exp['userName']), 'Staff')} (${isOwnClaim ? 'MANAGER' : ClaimWorkflowEngine.extractCreatorRole(exp)}) • ${_getString(exp['location'] is Map ? exp['location']['name'] : (exp['location'] ?? exp['branch']), userBranch)}",
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
                              creatorRole: isOwnClaim ? 'MANAGER' : ClaimWorkflowEngine.extractCreatorRole(exp),
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

                            if (canEditOwn) ...[
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: () => showDialog(context: context, builder: (_) => EditExpenseDialog(expense: exp, onUpdated: _loadData)),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: const Color(0xffEFF6FF), borderRadius: BorderRadius.circular(8)),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.edit, size: 14, color: Color(0xff2563EB)),
                                          SizedBox(width: 4),
                                          Text("Edit & Receipt", style: TextStyle(fontSize: 12, color: Color(0xff2563EB), fontWeight: FontWeight.bold)),
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
                            ],

                            if (!isOwnClaim && ClaimWorkflowEngine.isPendingForManager(statusStr, exp)) ...[
                              const Divider(height: 20),
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
                                        backgroundColor: const Color(0xff2563EB),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _processApproval(id, 'APPROVE'),
                                      child: const Text("Accept & Forward", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (ClaimWorkflowEngine.isPendingForOwner(statusStr, exp)) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xffFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xffFDE68A)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.schedule, size: 16, color: Colors.orange),
                                    const SizedBox(width: 6),
                                    Text(
                                      isOwnClaim
                                          ? "Submitted • Awaiting Owner Direct Approval"
                                          : "Manager Approved — Forwarded to Owner for Review",
                                      style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
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
                                      "Owner Approved — Waiting for Cashier Payout",
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
                                  border: Border.all(color: const Color(0xffBBF7D0)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.task_alt, size: 16, color: Colors.green),
                                    SizedBox(width: 6),
                                    Text(
                                      "Disbursed / Paid (Settled)",
                                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
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
          FloatingPillNavItem(icon: Icons.dashboard, label: 'Claims'),
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

  Widget _tabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 14, color: isSelected ? const Color(0xff2563EB) : Colors.grey),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isSelected ? const Color(0xff2563EB) : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
