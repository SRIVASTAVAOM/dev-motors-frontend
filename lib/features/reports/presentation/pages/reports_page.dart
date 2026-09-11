import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../expenses/presentation/widgets/expense_status_chip.dart';

class ReportsPage extends StatefulWidget {
  final VoidCallback? onBack;
  const ReportsPage({super.key, this.onBack});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = true;
  List<dynamic> _expenses = [];

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
      setState(() => _expenses = List<dynamic>.from(list));
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _total => _expenses.fold(0.0, (s, e) => s + _amt(e['amount']));
  double get _cleared => _expenses
      .where((e) => _get(e['status']).toUpperCase().contains('PAID') || _get(e['status']).toUpperCase().contains('APPROVED_2'))
      .fold(0.0, (s, e) => s + _amt(e['amount']));

  Map<String, double> get _categoryWise {
    final Map<String, double> m = {};
    for (var e in _expenses) {
      final cat = _get(e['category'], 'Fuel');
      final val = _amt(e['amount']);
      m[cat] = (m[cat] ?? 0) + val;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final catMap = _categoryWise;

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
        title: const Text("Expense Reports & Analytics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black87), onPressed: _fetch)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Total Claims Volume", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text("₹${_total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                              const SizedBox(height: 2),
                              Text("${_expenses.length} claims in database", style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Cleared / Approved Payouts", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text("₹${_cleared.toStringAsFixed(0)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                              const SizedBox(height: 2),
                              const Text("Settled records", style: TextStyle(fontSize: 11, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Category-wise Dynamic Breakdown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (catMap.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text("No expenses to show", style: TextStyle(color: Colors.grey))),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: catMap.entries.map((entry) {
                          final pct = _total > 0 ? (entry.value / _total) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text("₹${entry.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(1)}%)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                    ),
                  const SizedBox(height: 24),
                  const Text("Audit Timeline", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final e = _expenses[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xffEFF6FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.receipt, color: Color(0xff2563EB), size: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_get(e['description'], 'Claim'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text("${_get(e['category'], 'Fuel')} • ${_get(e['employeeName'] ?? e['employeeId'], 'Staff')}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("₹${_amt(e['amount']).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                ExpenseStatusChip(status: _get(e['status'], 'PENDING')),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
