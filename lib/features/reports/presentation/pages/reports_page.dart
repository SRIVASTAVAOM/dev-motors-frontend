import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/export_helper.dart';
import '../../../expenses/presentation/widgets/expense_status_chip.dart';
import '../../../expenses/presentation/widgets/receipt_viewer_dialog.dart';

class ReportsPage extends StatefulWidget {
  final VoidCallback? onBack;
  const ReportsPage({super.key, this.onBack});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = true;
  List<dynamic> _expenses = [];

  // Filter States
  String _dateFilter = 'ALL'; // 'ALL', 'THIS_MONTH', 'LAST_30_DAYS'
  String _statusFilter = 'ALL'; // 'ALL', 'PAID', 'PENDING'
  String _selectedBranch = 'ALL'; // 'ALL' or branch name

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  String _get(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    if (val is String) return val;
    if (val is Map) return val['name']?.toString() ?? val['status']?.toString() ?? fallback;
    return val.toString();
  }

  double _amt(dynamic val) => double.tryParse(val?.toString() ?? '0') ?? 0.0;

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getExpenses();
      if (mounted) {
        setState(() => _expenses = List<dynamic>.from(list));
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Extract distinct branches from dataset
  List<String> get _availableBranches {
    final s = <String>{};
    for (var e in _expenses) {
      if (e is Map) {
        final loc = _get(e['location']);
        if (loc.isNotEmpty && loc != 'Main Dealership' && loc != 'All') {
          s.add(loc);
        }
      }
    }
    return ['ALL', ...s.toList()..sort()];
  }

  // Filtered dataset based on current filter selections
  List<dynamic> get _filteredExpenses {
    final now = DateTime.now();
    return _expenses.where((e) {
      if (e is! Map) return false;

      // 1. Branch filter
      if (_selectedBranch != 'ALL') {
        final loc = _get(e['location']);
        if (loc != _selectedBranch) return false;
      }

      // 2. Status filter
      final status = _get(e['status']).toUpperCase();
      if (_statusFilter == 'PAID') {
        if (!status.contains('PAID') && !status.contains('APPROVED_2')) return false;
      } else if (_statusFilter == 'PENDING') {
        if (status.contains('PAID') || status.contains('REJECTED')) return false;
      }

      // 3. Date filter
      if (_dateFilter != 'ALL' && e['createdAt'] != null) {
        try {
          final dt = DateTime.parse(e['createdAt']);
          if (_dateFilter == 'THIS_MONTH') {
            if (dt.year != now.year || dt.month != now.month) return false;
          } else if (_dateFilter == 'LAST_30_DAYS') {
            if (now.difference(dt).inDays > 30) return false;
          }
        } catch (_) {}
      }

      return true;
    }).toList();
  }

  double get _total => _filteredExpenses.fold(0.0, (s, e) => s + _amt(e['amount']));

  double get _cleared => _filteredExpenses
      .where((e) => _get(e['status']).toUpperCase().contains('PAID') || _get(e['status']).toUpperCase().contains('APPROVED_2'))
      .fold(0.0, (s, e) => s + _amt(e['amount']));

  double get _pending => _filteredExpenses
      .where((e) {
        final st = _get(e['status']).toUpperCase();
        return !st.contains('PAID') && !st.contains('REJECTED');
      })
      .fold(0.0, (s, e) => s + _amt(e['amount']));

  Map<String, double> get _categoryWise {
    final Map<String, double> m = {};
    for (var e in _filteredExpenses) {
      final cat = _get(e['category'], 'General Expenses');
      final val = _amt(e['amount']);
      m[cat] = (m[cat] ?? 0) + val;
    }
    return m;
  }

  void _exportCsv() {
    if (_filteredExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No records to export in current filter"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ExportHelper.exportExpensesToCsv(
      _filteredExpenses,
      branchName: _selectedBranch == 'ALL' ? 'All Dealerships' : _selectedBranch,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text("Expense ledger exported to CSV successfully!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openReceipt(Map<String, dynamic> expense) {
    final hasReceipt = expense['receiptUrl'] != null ||
        expense['receiptImage'] != null ||
        expense['receiptBase64'] != null ||
        expense['receiptFileName'] != null;

    if (!hasReceipt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No receipt image attached to this voucher"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => ReceiptViewerDialog(
        receiptData: expense,
        title: _get(expense['description'], "Expense Receipt"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catMap = _categoryWise;
    final branches = _availableBranches;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          tooltip: "Back to Dashboard",
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          "Expense Reports & Analytics",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xff2563EB)),
            tooltip: "Export Filtered CSV",
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: "Refresh Data",
            onPressed: _fetch,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─────────────────────────────────────────
                    // 1. FILTER CONTROLS BAR
                    // ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune_rounded, size: 16, color: Color(0xff2563EB)),
                              const SizedBox(width: 6),
                              const Text(
                                "Quick Filters",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff1E293B)),
                              ),
                              const Spacer(),
                              if (_dateFilter != 'ALL' || _statusFilter != 'ALL' || _selectedBranch != 'ALL')
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _dateFilter = 'ALL';
                                      _statusFilter = 'ALL';
                                      _selectedBranch = 'ALL';
                                    });
                                  },
                                  child: const Text(
                                    "Reset Filters",
                                    style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Date Filter Pills
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: "All Time",
                                  isSelected: _dateFilter == 'ALL',
                                  onSelected: () => setState(() => _dateFilter = 'ALL'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: "This Month",
                                  icon: Icons.calendar_today_rounded,
                                  isSelected: _dateFilter == 'THIS_MONTH',
                                  onSelected: () => setState(() => _dateFilter = 'THIS_MONTH'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: "Last 30 Days",
                                  icon: Icons.history_rounded,
                                  isSelected: _dateFilter == 'LAST_30_DAYS',
                                  onSelected: () => setState(() => _dateFilter = 'LAST_30_DAYS'),
                                ),
                                const SizedBox(width: 12),
                                Container(width: 1, height: 20, color: Colors.grey.shade300),
                                const SizedBox(width: 12),

                                // Status Filters
                                _buildFilterChip(
                                  label: "All Status",
                                  isSelected: _statusFilter == 'ALL',
                                  onSelected: () => setState(() => _statusFilter = 'ALL'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: "Settled (Paid)",
                                  icon: Icons.check_circle_outline,
                                  isSelected: _statusFilter == 'PAID',
                                  onSelected: () => setState(() => _statusFilter == 'PAID'),
                                  activeColor: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: "Pending",
                                  icon: Icons.pending_actions,
                                  isSelected: _statusFilter == 'PENDING',
                                  onSelected: () => setState(() => _statusFilter == 'PENDING'),
                                  activeColor: Colors.orange.shade700,
                                ),
                              ],
                            ),
                          ),

                          // Branch Filter (If multiple branches available)
                          if (branches.length > 2) ...[
                            const SizedBox(height: 10),
                            Divider(color: Colors.grey.shade200, height: 1),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text("Branch: ", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: branches.map((b) {
                                        final isSel = _selectedBranch == b;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: ChoiceChip(
                                            label: Text(b == 'ALL' ? 'All Dealerships' : b, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                                            selected: isSel,
                                            selectedColor: const Color(0xff2563EB),
                                            backgroundColor: Colors.grey.shade100,
                                            onSelected: (_) => setState(() => _selectedBranch = b),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─────────────────────────────────────────
                    // 2. THREE EXECUTIVE METRICS CARDS
                    // ─────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: "Total Volume",
                            value: "₹${_total.toStringAsFixed(0)}",
                            subtext: "${_filteredExpenses.length} claims in view",
                            color: const Color(0xff2563EB),
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryCard(
                            title: "Settled / Paid",
                            value: "₹${_cleared.toStringAsFixed(0)}",
                            subtext: "Funds Disbursed",
                            color: Colors.green,
                            icon: Icons.verified_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: "Pending Payouts",
                            value: "₹${_pending.toStringAsFixed(0)}",
                            subtext: "Awaiting Action",
                            color: Colors.orange.shade700,
                            icon: Icons.pending_actions_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _exportCsv,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xffECFDF5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xffA7F3D0)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Excel / CSV", style: TextStyle(fontSize: 12, color: Color(0xff065F46), fontWeight: FontWeight.w600)),
                                      Icon(Icons.file_download_outlined, color: Color(0xff059669), size: 20),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text("Export Ledger", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff047857))),
                                  SizedBox(height: 2),
                                  Text("Download CSV statement", style: TextStyle(fontSize: 11, color: Color(0xff059669))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─────────────────────────────────────────
                    // 3. CATEGORY-WISE DYNAMIC BREAKDOWN
                    // ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Category-wise Breakdown",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff1E293B)),
                              ),
                              Text(
                                "${catMap.length} Categories",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (catMap.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text("No expenses found matching the selected filters", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ),
                            )
                          else
                            Column(
                              children: catMap.entries.map((entry) {
                                final pct = _total > 0 ? (entry.value / _total) : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 7),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          Text(
                                            "₹${entry.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(1)}%)",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff0F172A)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          backgroundColor: Colors.grey.shade100,
                                          color: const Color(0xff2563EB),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─────────────────────────────────────────
                    // 4. AUDIT TIMELINE (DETAILED LEDGER)
                    // ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Audit Timeline",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1E293B)),
                        ),
                        Text(
                          "${_filteredExpenses.length} Records",
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_filteredExpenses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("No expense claims in this filter", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            SizedBox(height: 4),
                            Text("Try changing date or status filters above", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredExpenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final e = _filteredExpenses[i];
                          final hasReceipt = e['receiptUrl'] != null ||
                              e['receiptImage'] != null ||
                              e['receiptBase64'] != null ||
                              e['receiptFileName'] != null;

                          final empName = e['employee'] is Map
                              ? (e['employee']['name'] ?? e['employee']['employeeId'] ?? 'Staff')
                              : (e['employeeName'] ?? e['employeeId'] ?? 'Staff');

                          String dateStr = '';
                          if (e['createdAt'] != null) {
                            try {
                              dateStr = DateFormat('dd MMM, hh:mm a').format(DateTime.parse(e['createdAt']));
                            } catch (_) {}
                          }

                          return InkWell(
                            onTap: () => _openReceipt(e),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xff2563EB), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _get(e['description'], 'Claim'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${_get(e['category'], 'General')} • $empName",
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (dateStr.isNotEmpty)
                                              Text(
                                                dateStr,
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                              ),
                                            if (hasReceipt) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xffEFF6FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.image_outlined, size: 11, color: Color(0xff2563EB)),
                                                    SizedBox(width: 3),
                                                    Text("Receipt", style: TextStyle(fontSize: 10, color: Color(0xff2563EB), fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "₹${_amt(e['amount']).toStringAsFixed(0)}",
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xff0F172A)),
                                      ),
                                      const SizedBox(height: 4),
                                      ExpenseStatusChip(status: _get(e['status'], 'PENDING')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
    Color? activeColor,
  }) {
    final color = activeColor ?? const Color(0xff2563EB);
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xff334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(subtext, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
