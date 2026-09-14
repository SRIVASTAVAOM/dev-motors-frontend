import '../../../expenses/presentation/widgets/receipt_viewer_dialog.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/edit_expense_dialog.dart';
import '../widgets/floating_pill_nav_bar.dart';
import '../../../profile/presentation/widgets/profile_sheet.dart';
import '../../../profile/presentation/widgets/change_password_dialog.dart';
import '../../../expenses/presentation/widgets/approval_stepper.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../../core/utils/claim_workflow_engine.dart';
import '../../../../core/services/csv_export_service.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  int _navIndex = 0;
  int _selectedTab = 0;
  bool _isLoading = true;
  List<dynamic> _expenses = [];
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _serverNotifs = [];

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

  Future<void> _markPaid(String id) async {
    if (id.isEmpty) return;

    ClaimWorkflowEngine.markCashierPaid(id);
    await ApiService.processApproval(
      expenseId: id,
      action: 'PAID',
      comments: 'Disbursed cash to employee',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Payment disbursed & marked as PAID!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Color(0xff10B981),
          duration: Duration(seconds: 3),
        ),
      );
    }
    _loadData();
  }

  Future<void> _deleteExpense(String id) async {
    final ok = await ApiService.deleteExpense(id);
    if (ok) {
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Claim deleted!")));
    }
  }

  bool _showAllBranches = true;

  bool get _isSeniorCashier => ClaimWorkflowEngine.isSeniorCashier(_profile ?? ApiService.currentUser);

  bool _isClaimCreatedByMe(dynamic exp) {
    return ClaimWorkflowEngine.isClaimCreatedByUser(exp, _profile ?? ApiService.currentUser);
  }

  List<dynamic> get _payoutQueue => _expenses.where((e) {
    if (e is! Map) return false;
    final userBranch = _getString(_profile?['branch'] ?? _profile?['location'], '');
    if (!_isSeniorCashier || !_showAllBranches) {
      final rawBranch = e['branch'] ?? (e['location'] is Map ? e['location']['name'] : e['location']);
      if (userBranch.isNotEmpty && !ClaimWorkflowEngine.matchesBranch(userBranch: userBranch, expenseBranch: rawBranch, currentUser: _profile ?? ApiService.currentUser)) {
        return false;
      }
    }
    final status = e['status'];
    return ClaimWorkflowEngine.isPendingForCashier(status, e);
  }).toList();

  List<dynamic> get _myClaims {
    final me = _profile ?? ApiService.currentUser;
    if (me == null) return [];
    return _expenses.where((e) {
      if (e is! Map) return false;
      return ClaimWorkflowEngine.isClaimCreatedByUser(e, me) &&
          !ClaimWorkflowEngine.isSettledOrRejected(e['status'], e);
    }).toList();
  }

  List<dynamic> get _historyList => _expenses.where((e) {
    if (e is! Map) return false;
    return ClaimWorkflowEngine.isSettledOrRejected(e['status'], e);
  }).toList();

  @override
  Widget build(BuildContext context) {
    if (_navIndex == 1) {
      return ReportsPage(onBack: () => setState(() => _navIndex = 0));
    }

    final userName = _getString(_profile?['name'], "Cashier");
    final userOccupation = _getString(_profile?['designation'], "Cashier & Accounts");
    final userBranch = _getString(_profile?['branch'] ?? _profile?['location'], "Main Outlet");

    final notifs = NotificationService.getNotificationsForRole(
      'CASHIER',
      _expenses,
      userBranch: userBranch,
      currentUser: _profile ?? ApiService.currentUser,
      serverNotifications: _serverNotifs,
    );
    List<dynamic> currentList;
    if (_selectedTab == 0) {
      currentList = _payoutQueue;
    } else if (_selectedTab == 1) {
      currentList = _myClaims;
    } else {
      currentList = _historyList;
    }

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
                      backgroundColor: Color(0xffDCFCE7),
                      child: Icon(Icons.point_of_sale, color: Color(0xff16A34A), size: 22),
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
                                  color: const Color(0xffDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xffBBF7D0), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.account_balance_wallet_outlined, size: 11, color: Color(0xff16A34A)),
                                    const SizedBox(width: 4),
                                    Text(
                                      userOccupation,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xff16A34A),
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
                            'CASHIER',
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
                            filenamePrefix: 'dev_motors_cashier_ledger',
                            branch: userBranch,
                          );
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Ledger exported as CSV for Tally/Excel!"),
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
                              Expanded(child: Text('Export Disbursal CSV', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
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
                      _tabItem(0, "Payouts (${_payoutQueue.length})", Icons.payments),
                      _tabItem(1, "My Claims (${_myClaims.length})", Icons.receipt_long),
                      _tabItem(2, "History (${_historyList.length})", Icons.history),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_isSeniorCashier && _selectedTab == 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xffEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xff2563EB), size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Senior / Chief Cashier Oversight",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff1E40AF)),
                              ),
                              Text(
                                "All Dealership Branches Payout Authority",
                                style: TextStyle(fontSize: 11, color: Color(0xff3B82F6)),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _showAllBranches = !_showAllBranches),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _showAllBranches ? const Color(0xff2563EB) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xff2563EB)),
                            ),
                            child: Text(
                              _showAllBranches ? "All Branches" : "My Branch",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _showAllBranches ? Colors.white : const Color(0xff2563EB),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                                ? "No claims ready for payout"
                                : (_selectedTab == 1 ? "No claims submitted by you" : "No payment history logs"),
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
                                        "${_getString(exp['employeeName'], isOwnClaim ? 'My Expense' : 'Staff')} • ${_getString(exp['location'], 'Dealership')}",
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
                              creatorRole: isOwnClaim ? 'CASHIER' : ClaimWorkflowEngine.extractCreatorRole(exp),
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
                                          Text("Edit", style: TextStyle(fontSize: 12, color: Color(0xff2563EB), fontWeight: FontWeight.bold)),
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

                            if (_selectedTab == 0 && ClaimWorkflowEngine.isPendingForCashier(statusStr, exp)) ...[
                              const Divider(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text("Mark as Paid (Disburse Cash)", style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () => _markPaid(id),
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
          FloatingPillNavItem(icon: Icons.payments, label: 'Payouts'),
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
              Icon(icon, size: 14, color: isSelected ? Colors.green : Colors.grey),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isSelected ? Colors.green : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
