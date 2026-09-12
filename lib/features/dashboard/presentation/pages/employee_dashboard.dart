import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/claim_workflow_engine.dart';
import '../../../../core/utils/safe_parser.dart';
import '../../../expenses/presentation/widgets/approval_stepper.dart';
import '../../../expenses/presentation/widgets/receipt_viewer_dialog.dart';
import '../../../profile/presentation/widgets/profile_sheet.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/edit_expense_dialog.dart';
import '../widgets/floating_pill_nav_bar.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
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

  String _getString(dynamic val, [String fallback = '']) => SafeParser.getString(val, fallback);

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getExpenses();
      _profile = ApiService.currentUser;

      setState(() {
        _expenses = List<dynamic>.from(list);
      });
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  List<dynamic> get _myOwnExpenses => _expenses;

  List<dynamic> get _activeList => _myOwnExpenses.where((e) {
    if (e is! Map) return false;
    return ClaimWorkflowEngine.isVisibleInEmployeeActive(e['status'], e);
  }).toList();

  List<dynamic> get _historyList => _myOwnExpenses.where((e) {
    if (e is! Map) return false;
    return ClaimWorkflowEngine.isSettledOrRejected(e['status'], e);
  }).toList();

  @override
  Widget build(BuildContext context) {
    if (_navIndex == 1) {
      return ReportsPage(onBack: () => setState(() => _navIndex = 0));
    }

    final userName = _getString(_profile?['name'], "Staff Member");
    final userDesignation = _getString(_profile?['designation'], "Operations Staff");
    final userBranch = _profile?['location'] != null && _profile?['location'] is Map 
        ? _getString(_profile?['location']['name'], "Main Outlet") 
        : _getString(_profile?['branch'], "Main Outlet");

    final notifs = NotificationService.getNotificationsForRole(
      'EMPLOYEE',
      _myOwnExpenses,
      userBranch: userBranch,
      currentUser: _profile ?? ApiService.currentUser,
    );
    final currentList = _selectedTab == 0 ? _activeList : _historyList;

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
                // User Header with Branch & Designation
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xffEFF6FF),
                      child: Icon(Icons.person, color: Color(0xff2563EB), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xffEFF6FF), borderRadius: BorderRadius.circular(6)),
                                child: Text(userDesignation, style: const TextStyle(fontSize: 10, color: Color(0xff2563EB), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                              const SizedBox(width: 3),
                              Text(userBranch, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
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
                            'EMPLOYEE',
                            _myOwnExpenses,
                            () => setState(() {}),
                            currentUser: _profile ?? ApiService.currentUser,
                            userBranch: userBranch,
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
                    IconButton(tooltip: "Refresh", icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _loadData),
                    IconButton(
                      tooltip: "Profile",
                      icon: const Icon(Icons.person_outline, color: Colors.grey),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const ProfileSheet(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2-Tab Queue Switcher
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
                                const Icon(Icons.hourglass_top, size: 16, color: Color(0xff2563EB)),
                                const SizedBox(width: 6),
                                Text(
                                  "In-Progress (${_activeList.length})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedTab == 0 ? const Color(0xff2563EB) : Colors.grey.shade700,
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
                                const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  "Settled (${_historyList.length})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedTab == 1 ? const Color(0xff1E293B) : Colors.grey.shade700,
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
                          Icon(_selectedTab == 0 ? Icons.inbox_outlined : Icons.history, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _selectedTab == 0 ? "No active claims in progress" : "No settled claims yet",
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
                        final rawExp = currentList[idx];
                        final Map<String, dynamic> exp = (rawExp is Map) ? Map<String, dynamic>.from(rawExp) : {};
                        
                        // Safe extraction of status
                        final rawStatus = exp['status'];
                        final String statusStr = (rawStatus is Map) 
                            ? (rawStatus['name'] ?? rawStatus['status'] ?? 'PENDING').toString() 
                            : (rawStatus?.toString() ?? 'PENDING');

                        final rawReceipt = exp['receiptImage'] ?? exp['receiptUrl'] ?? '';
                        final receiptData = (rawReceipt is Map) ? '' : rawReceipt.toString();
                        final hasReceipt = receiptData.trim().isNotEmpty && receiptData != 'null';

                        final isPendingApproval1 = ClaimWorkflowEngine.isPendingForManager(statusStr, exp);

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
                              _buildLiveEmpTaskBar(exp),
                              const SizedBox(height: 8),
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
                                          "${_getString(exp['category'], 'General')} • ${_getString(exp['location'], userBranch)}",
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text("₹${SafeParser.getDouble(exp['amount']).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1E293B))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ApprovalStepper(
                                status: statusStr,
                                rejectionReason: ClaimWorkflowEngine.getRejectionRemark(
                                  _getString(exp['id']).isNotEmpty ? _getString(exp['id']) : _getString(exp['_id']),
                                  exp,
                                ),
                                creatorRole: 'EMPLOYEE',
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

                            if (isPendingApproval1) ...[
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
                                    onTap: () => _deleteExpense(_getString(exp['_id'] ?? exp['id'])),
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
          FloatingPillNavItem(icon: Icons.receipt_long, label: 'Claims'),
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

  Widget _buildLiveEmpTaskBar(dynamic rawExp) {
    final exp = (rawExp is Map) ? rawExp : <String, dynamic>{};
    final rawStatus = exp['status'];
    String s = '';
    if (rawStatus is String) {
      s = rawStatus.toUpperCase();
    } else if (rawStatus is Map) {
      s = (rawStatus['name'] ?? rawStatus['status'] ?? '').toString().toUpperCase();
    }

    Color bg = const Color(0xffF1F5F9);
    Color fg = const Color(0xff475569);
    String label = 'Pending Review';

    if (s.contains('PAID') || s.contains('DISBURSED') || s.contains('SETTLE')) {
      bg = const Color(0xffDCFCE7);
      fg = const Color(0xff16A34A);
      label = 'Disbursed / Paid (Settled)';
    } else if (s.contains('REJECT')) {
      bg = const Color(0xffFEE2E2);
      fg = const Color(0xffDC2626);
      label = 'Rejected';
    } else if (s.contains('PENDING_CASHIER') || s.contains('APPROVED_2') || s.contains('OWNER_APPROVED') || s.contains('APPROVED_OWNER')) {
      bg = const Color(0xffF3E8FF);
      fg = const Color(0xff7E22CE);
      label = 'Approved by Owner • Ready for Cashier Payout';
    } else if (s.contains('PENDING_OWNER') || s.contains('APPROVED_1') || s.contains('MANAGER_APPROVED') || s == 'APPROVED') {
      bg = const Color(0xffFEF3C7);
      fg = const Color(0xffD97706);
      label = 'Approved by Manager • In Review with Owner';
    } else if (s.contains('MANAGER') || s.contains('SUBMITTED') || s.contains('PENDING')) {
      bg = const Color(0xffEFF6FF);
      fg = const Color(0xff2563EB);
      label = 'Submitted • In Review with Branch Manager';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

}
