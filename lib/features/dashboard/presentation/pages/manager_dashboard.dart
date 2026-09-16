import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../../core/utils/claim_workflow_engine.dart';
import '../../../../core/utils/safe_parser.dart';
import '../../../expenses/presentation/widgets/reject_claim_dialog.dart';
import '../../../expenses/presentation/widgets/unified_claim_card.dart';
import '../../../profile/presentation/widgets/profile_sheet.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/edit_expense_dialog.dart';
import '../widgets/floating_pill_nav_bar.dart';
import '../widgets/pill_tab_bar.dart';
import '../widgets/unified_executive_header.dart';

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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getExpenses();
      _profile = ApiService.currentUser;
      _serverNotifs = await ApiService.getNotifications();

      setState(() {
        _expenses = List<dynamic>.from(list);
      });
    } catch (_) {
    } finally {
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
            backgroundColor: isApprove ? AppColors.success : AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e"), backgroundColor: AppColors.danger),
        );
      }
    }
    await _loadData();
    if (mounted) setState(() => _isLoading = false);
  }

  void _showRejectDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => RejectClaimDialog(
        expenseId: id,
        onConfirm: (reason) => _processApproval(id, 'REJECT', reason: reason),
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
        if (_isClaimCreatedByMe(e)) return false;
        final status = e['status'];
        return ClaimWorkflowEngine.isPendingForManager(status, e);
      }).toList();

  List<dynamic> get _actionNeededList {
    final mgrBranch = _currentMgrBranch;
    final pending = _allPendingClaims;

    if (_showAllBranches) return pending;

    return pending.where((e) {
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UnifiedExecutiveHeader(
                  role: 'MANAGER',
                  userName: userName,
                  userOccupation: userOccupation,
                  userBranch: userBranch,
                  expenses: _expenses,
                  serverNotifications: _serverNotifs,
                  onRefresh: _loadData,
                  onExportCsv: () async {
                    final ok = await CsvExportService.exportExpensesToCsv(
                      _expenses,
                      filenamePrefix: 'dev_motors_${userBranch.replaceAll(" ", "_").toLowerCase()}_ledger',
                      branch: userBranch,
                    );
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$userBranch ledger exported as CSV!"),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 18),
                PillTabBar(
                  selectedIndex: _selectedTab,
                  tabs: [
                    PillTabItem(
                      label: "Action",
                      count: _actionNeededList.length,
                      icon: Icons.pending_actions_rounded,
                    ),
                    PillTabItem(
                      label: "My Claims",
                      count: _myClaimsList.length,
                      icon: Icons.person_pin_rounded,
                    ),
                    PillTabItem(
                      label: "History",
                      count: _historyList.length,
                      icon: Icons.history_rounded,
                    ),
                  ],
                  onTabSelected: (idx) => setState(() => _selectedTab = idx),
                ),
                const SizedBox(height: 12),
                if (_selectedTab == 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showAllBranches ? "Showing: All Dealerships" : "Branch: $userBranch",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      InkWell(
                        onTap: () => setState(() => _showAllBranches = !_showAllBranches),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _showAllBranches ? AppColors.primaryLight : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _showAllBranches ? AppColors.primary : AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune, size: 12, color: _showAllBranches ? AppColors.primary : AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                _showAllBranches ? "My Branch Only" : "All Branches (${_allPendingClaims.length})",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _showAllBranches ? AppColors.primary : AppColors.textSecondary,
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
                          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            _selectedTab == 0
                                ? (_showAllBranches
                                    ? "No pending claims across any dealership"
                                    : "No pending claims for $userBranch")
                                : (_selectedTab == 1 ? "You haven't submitted any claims" : "No history logs yet"),
                            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final exp = Map<String, dynamic>.from(currentList[idx] is Map ? currentList[idx] : {});
                      final rawStatus = exp['status'];
                      final statusStr = (rawStatus is Map)
                          ? (rawStatus['name'] ?? rawStatus['status'] ?? 'PENDING').toString()
                          : (rawStatus?.toString() ?? 'PENDING');
                      final isOwnClaim = _isClaimCreatedByMe(exp);
                      final isPendingMgr = ClaimWorkflowEngine.isPendingForManager(statusStr, exp);
                      final canEditOwn = isOwnClaim && !statusStr.toUpperCase().contains('PAID');
                      final id = _getString(exp['id']).isNotEmpty ? _getString(exp['id']) : _getString(exp['_id']);

                      return UnifiedClaimCard(
                        expense: exp,
                        userBranch: userBranch,
                        isOwnClaim: isOwnClaim,
                        canApprove: !isOwnClaim && isPendingMgr,
                        canReject: !isOwnClaim && isPendingMgr,
                        canEdit: canEditOwn,
                        canDelete: canEditOwn,
                        onApprove: () => _processApproval(id, 'APPROVE'),
                        onReject: () => _showRejectDialog(id),
                        onEdit: () => showDialog(
                          context: context,
                          builder: (_) => EditExpenseDialog(expense: exp, onUpdated: _loadData),
                        ),
                        onDelete: () => _deleteExpense(id),
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
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Expense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => showDialog(context: context, builder: (_) => AddExpenseDialog(onCreated: _loadData)),
      ),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _navIndex,
        items: const [
          FloatingPillNavItem(icon: Icons.receipt_long_rounded, label: 'Claims'),
          FloatingPillNavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
          FloatingPillNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
        onTap: (idx) {
          if (idx == 2) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const ProfileSheet(),
            );
          } else {
            setState(() => _navIndex = idx);
          }
        },
      ),
    );
  }
}
