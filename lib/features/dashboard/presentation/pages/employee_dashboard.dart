import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
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

  Future<void> _deleteExpense(String id) async {
    final ok = await ApiService.deleteExpense(id);
    if (ok) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Claim deleted!")));
      }
    }
  }

  List<dynamic> get _myOwnExpenses {
    final me = _profile ?? ApiService.currentUser;
    if (me == null) return _expenses;
    return _expenses.where((e) {
      if (e is! Map) return false;
      return ClaimWorkflowEngine.isClaimCreatedByUser(e, me);
    }).toList();
  }

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
    final userOccupation = _getString(_profile?['designation'], "Operations Staff");
    final userBranch = _profile?['location'] != null && _profile?['location'] is Map
        ? _getString(_profile?['location']['name'], "Main Outlet")
        : _getString(_profile?['branch'], "Main Outlet");

    final currentList = _selectedTab == 0 ? _activeList : _historyList;

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
                  role: 'EMPLOYEE',
                  userName: userName,
                  userOccupation: userOccupation,
                  userBranch: userBranch,
                  expenses: _myOwnExpenses,
                  serverNotifications: _serverNotifs,
                  onRefresh: _loadData,
                ),
                const SizedBox(height: 18),
                PillTabBar(
                  selectedIndex: _selectedTab,
                  tabs: [
                    PillTabItem(
                      label: "In-Progress",
                      count: _activeList.length,
                      icon: Icons.hourglass_top_rounded,
                    ),
                    PillTabItem(
                      label: "Settled",
                      count: _historyList.length,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ],
                  onTabSelected: (idx) => setState(() => _selectedTab = idx),
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
                          Icon(
                            _selectedTab == 0 ? Icons.inbox_outlined : Icons.history_rounded,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedTab == 0 ? "No active claims in progress" : "No settled claims yet",
                            style: const TextStyle(color: AppColors.textSecondary),
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
                      final isPending = ClaimWorkflowEngine.isPendingForManager(statusStr, exp);
                      final expId = _getString(exp['_id'] ?? exp['id']);

                      return UnifiedClaimCard(
                        expense: exp,
                        userBranch: userBranch,
                        isOwnClaim: true,
                        canEdit: isPending,
                        canDelete: isPending,
                        onEdit: () => showDialog(
                          context: context,
                          builder: (_) => EditExpenseDialog(expense: exp, onUpdated: _loadData),
                        ),
                        onDelete: () => _deleteExpense(expId),
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
