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
        action: action == 'APPROVE' ? 'APPROVED_2' : action,
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
                        ? "Claim approved and forwarded to Cashier for Payout!"
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
        onConfirm: (reason) => _processApproval(id, 'REJECTED', reason: reason),
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

    final currentList = _selectedTab == 0 ? _reviewQueue : _allClaims;

    final userName = _getString(_profile?['name'], "Dev Motors");
    final userOccupation = _getString(_profile?['designation'], "Managing Director / Owner");
    final userBranch = _getString(_profile?['branch'], "All Dealerships Oversight");

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
                  role: 'OWNER',
                  userName: userName,
                  userOccupation: userOccupation,
                  userBranch: userBranch,
                  expenses: _expenses,
                  serverNotifications: _serverNotifs,
                  onRefresh: _loadData,
                  onExportCsv: () async {
                    final ok = await CsvExportService.exportExpensesToCsv(
                      _expenses,
                      filenamePrefix: 'dev_motors_company_ledger',
                      branch: 'All Branches',
                    );
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Company ledger exported as CSV!"),
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
                      label: "Action Needed",
                      count: _reviewQueue.length,
                      icon: Icons.pending_actions_rounded,
                    ),
                    PillTabItem(
                      label: "All Company Claims",
                      count: _allClaims.length,
                      icon: Icons.domain_verification_rounded,
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
                          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            _selectedTab == 0 ? "No claims in review queue" : "No expense claims registered yet",
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
                      final isPendingOwner = ClaimWorkflowEngine.isPendingForOwner(statusStr, exp);
                      final isOwnClaim = ClaimWorkflowEngine.isClaimCreatedByUser(exp, _profile ?? ApiService.currentUser);
                      final canEditOwn = isOwnClaim && !statusStr.toUpperCase().contains('PAID');
                      final id = _getString(exp['id']).isNotEmpty ? _getString(exp['id']) : _getString(exp['_id']);

                      return UnifiedClaimCard(
                        expense: exp,
                        userBranch: userBranch,
                        isOwnClaim: isOwnClaim,
                        canApprove: isPendingOwner,
                        canReject: isPendingOwner,
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
