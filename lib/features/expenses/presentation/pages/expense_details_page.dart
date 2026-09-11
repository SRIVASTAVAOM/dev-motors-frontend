import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/status_helper.dart';

class ExpenseDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? expense;
  final String? currentUserRole;

  const ExpenseDetailsPage({
    super.key,
    this.expense,
    this.currentUserRole,
  });

  @override
  State<ExpenseDetailsPage> createState() => _ExpenseDetailsPageState();
}

class _ExpenseDetailsPageState extends State<ExpenseDetailsPage> {
  Map<String, dynamic> _currentExpense = {};
  List<dynamic> _timeline = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentExpense = widget.expense ?? {
      'id': 'temp-id',
      'amount': 0.0,
      'status': 'PENDING_MANAGER',
      'description': 'No details provided',
      'expenseDate': DateTime.now().toString().split(' ')[0],
      'category': {'name': 'General'}
    };
    if (widget.expense?['id'] != null) {
      _fetchTimeline();
    }
  }

  Future<void> _fetchTimeline() async {
    final timeline = await ApiService.getExpenseTimeline(_currentExpense['id']);
    if (mounted) {
      setState(() => _timeline = timeline);
    }
  }

  Future<void> _handleAction(String action, {double? newAmount, String? remarks}) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.processApproval(
        expenseId: _currentExpense['id'],
        action: action,
        newAmount: newAmount,
        remarks: remarks,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Action completed successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Expense'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Remarks / Reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction('REJECT', remarks: controller.text.trim());
            },
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
  }

  void _showOwnerEditDialog() {
    final amountController = TextEditingController(text: _currentExpense['amount'].toString());
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Amount & Approve'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'New Amount (INR)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(labelText: 'Reason for edit'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountController.text.trim());
              Navigator.pop(ctx);
              if (val != null) {
                _handleAction('APPROVE', newAmount: val, remarks: remarksController.text.trim());
              }
            },
            child: const Text('APPROVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentExpense['status'] ?? 'PENDING_MANAGER';
    final role = (widget.currentUserRole ?? 'EMPLOYEE').toUpperCase();

    final canManagerApprove = (role == 'MANAGER' && (status == 'PENDING' || status == 'PENDING_MANAGER'));
    final canOwnerApprove = (role == 'OWNER' && (status == 'APPROVED_1' || status == 'PENDING_OWNER'));
    final canCashierProcess = (role == 'CASHIER' && (status == 'APPROVED_2' || status == 'PENDING_CASHIER' || status == 'PENDING_FINANCE'));

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INR ${_currentExpense['amount']}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text(
                                StatusHelper.getReadableStatus(status),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: StatusHelper.getStatusColor(status),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text('Category: ${_currentExpense['category']?['name'] ?? 'General'}'),
                        const SizedBox(height: 4),
                        Text('Date: ${_currentExpense['expenseDate'] ?? 'N/A'}'),
                        const SizedBox(height: 4),
                        Text('Description: ${_currentExpense['description'] ?? 'No description'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Approval Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_timeline.isEmpty)
                  const Text('No timeline activity yet.', style: TextStyle(color: Colors.grey))
                else
                  ..._timeline.map((item) => ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(StatusHelper.getReadableAuditAction(item['action'] ?? '')),
                        subtitle: Text(item['remarks'] ?? item['createdAt'] ?? ''),
                      )),
                const SizedBox(height: 24),
                if (canManagerApprove || canCashierProcess)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showRejectDialog,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('REJECT'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleAction('APPROVE'),
                          child: Text(role == 'CASHIER' ? 'PROCESS & PAY' : 'APPROVE'),
                        ),
                      ),
                    ],
                  ),
                if (canOwnerApprove)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showRejectDialog,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('REJECT'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showOwnerEditDialog,
                          child: const Text('EDIT & APPROVE'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}
