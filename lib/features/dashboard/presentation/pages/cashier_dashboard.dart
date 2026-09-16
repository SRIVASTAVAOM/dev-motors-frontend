import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../../core/utils/claim_workflow_engine.dart';
import '../../../../core/utils/safe_parser.dart';
import '../../../expenses/presentation/widgets/unified_claim_card.dart';
import '../../../profile/presentation/widgets/profile_sheet.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/edit_expense_dialog.dart';
import '../widgets/floating_pill_nav_bar.dart';
import '../widgets/pill_tab_bar.dart';
import '../widgets/unified_executive_header.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  int _navIndex = 0;
  int _selectedTab = 0;
  bool _isLoading = true;
  bool _showAllBranches = true;
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
          backgroundColor: AppColors.success,
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

  bool get _isSeniorCashier => ClaimWorkflowEngine.isSeniorCashier(_profile ?? ApiService.currentUser);

  bool _isClaimCreatedByMe(dynamic exp) {
    return ClaimWorkflowEngine.isClaimCreatedByUser(exp, _profile ?? ApiService.currentUser);
  }

  List<dynamic> get _payoutQueue => _expenses.where((e) {
        if (e is! Map) return false;
        final userBranch = _getString(_profile?['branch'] ?? _profile?['location'], '');
        if (!_isSeniorCashier || !_showAllBranches) {
          final rawBranch = e['branch'] ?? (e['location'] is Map ? e['location']['name'] : e['location']);
          if (userBranch.isNotEmpty &&
              !ClaimWorkflowEngine.matchesBranch(
                userBranch: userBranch,
                expenseBranch: rawBranch,
                currentUser: _profile ?? ApiService.currentUser,
              )) {
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

    List<dynamic> currentList;
    if (_selectedTab == 0) {
      currentList = _payoutQueue;
    } else if (_selectedTab == 1) {
      currentList = _myClaims;
    } else {
      currentList = _historyList;
    }

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
                  role: 'CASHIER',
                  userName: userName,
                  userOccupation: userOccupation,
                  userBranch: userBranch,
                  expenses: _expenses,
                  serverNotifications: _serverNotifs,
                  onRefresh: _loadData,
                  onExportCsv: () async {
                    final ok = await CsvExportService.exportExpensesToCsv(
                      _expenses,
                      filenamePrefix: 'dev_motors_cashier_disbursement_ledger',
                      branch: userBranch,
                    );
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Payout ledger exported as CSV!"),
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
                      label: "Payout Queue",
                      count: _payoutQueue.length,
                      icon: Icons.payments_rounded,
                    ),
                    PillTabItem(
                      label: "My Claims",
                      count: _myClaims.length,
                      icon: Icons.person_pin_rounded,
                    ),
                    PillTabItem(
                      label: "Settled Ledger",
                      count: _historyList.length,
                      icon: Icons.history_rounded,
                    ),
                  ],
                  onTabSelected: (idx) => setState(() => _selectedTab = idx),
                ),
                const SizedBox(height: 12),
                if (_selectedTab == 0 && _isSeniorCashier) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showAllBranches ? "Showing: All Dealership Payouts" : "Branch: $userBranch",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      InkWell(
                        onTap: () => setState(() => _showAllBranches = !_showAllBranches),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _showAllBranches ? AppColors.infoLight : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _showAllBranches ? AppColors.info : AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune, size: 12, color: _showAllBranches ? AppColors.info : AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                _showAllBranches ? "My Branch Only" : "All Branches",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _showAllBranches ? AppColors.info : AppColors.textSecondary,
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
                                ? "No claims waiting for cash payout"
                                : (_selectedTab == 1 ? "You haven't submitted any claims" : "No settlement history logs"),
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
                      final isPendingCashier = ClaimWorkflowEngine.isPendingForCashier(statusStr, exp);
                      final canEditOwn = isOwnClaim && !statusStr.toUpperCase().contains('PAID');
                      final id = _getString(exp['id']).isNotEmpty ? _getString(exp['id']) : _getString(exp['_id']);

                      return UnifiedClaimCard(
                        expense: exp,
                        userBranch: userBranch,
                        isOwnClaim: isOwnClaim,
                        canPay: _selectedTab == 0 && isPendingCashier,
                        canEdit: canEditOwn,
                        canDelete: canEditOwn,
                        onPay: () => _markPaid(id),
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
