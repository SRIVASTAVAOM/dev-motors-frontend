import 'package:flutter/material.dart';
import '../../../../core/utils/export_helper.dart';

class AnalyticsDashboardCard extends StatelessWidget {
  final List<dynamic> expenses;

  const AnalyticsDashboardCard({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;
    double paidAmount = 0;
    double pendingAmount = 0;

    for (var e in expenses) {
      final amt = (e['amount'] as num?)?.toDouble() ?? 0;
      final status = (e['status'] ?? '').toString().toUpperCase();
      totalAmount += amt;
      if (status == 'PAID' || status == 'APPROVED') {
        paidAmount += amt;
      } else {
        pendingAmount += amt;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Expenses',
                value: '₹${totalAmount.toStringAsFixed(0)}',
                color: const Color(0xff2563EB),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Settled (Paid)',
                value: '₹${paidAmount.toStringAsFixed(0)}',
                color: Colors.green,
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Pending Claims',
                value: '₹${pendingAmount.toStringAsFixed(0)}',
                color: Colors.orange,
                icon: Icons.pending_actions_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Claims',
                value: '${expenses.length}',
                color: Colors.purple,
                icon: Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Export Report Action Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.table_chart_outlined, color: Color(0xff2563EB), size: 20),
                  SizedBox(width: 8),
                  Text('Audit & Accounting Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Download ledger statements with breakdown for GST and CA audit.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: expenses.isEmpty
                      ? null
                      : () => ExportHelper.exportExpensesToCsv(expenses),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Report to Excel (CSV)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 18,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
