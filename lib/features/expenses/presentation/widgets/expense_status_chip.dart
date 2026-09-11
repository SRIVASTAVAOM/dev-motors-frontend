import 'package:flutter/material.dart';

class ExpenseStatusChip extends StatelessWidget {
  final dynamic status;

  const ExpenseStatusChip({super.key, required this.status});

  String _clean(dynamic val) {
    if (val == null) return 'PENDING';
    if (val is String) return val;
    if (val is Map) return val['status']?.toString() ?? val['name']?.toString() ?? 'PENDING';
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final raw = _clean(status).toUpperCase().trim();

    String label = "Pending Approval 1";
    Color bg = const Color(0xffFEF3C7);
    Color textCol = const Color(0xffD97706);
    IconData icon = Icons.hourglass_top;

    if (raw.contains('PAID') || raw.contains('DISBURSED') || raw.contains('SETTLED')) {
      label = "Paid / Disbursed";
      bg = const Color(0xffDCFCE7);
      textCol = const Color(0xff16A34A);
      icon = Icons.check_circle;
    } else if (raw.contains('APPROVED_2') || raw.contains('OWNER_APPROVED')) {
      label = "Approved to be Paid";
      bg = const Color(0xffEFF6FF);
      textCol = const Color(0xff2563EB);
      icon = Icons.verified;
    } else if (raw.contains('APPROVED_1') || raw.contains('MANAGER_APPROVED') || raw.contains('ACCEPTED')) {
      label = "Approval 1 Cleared (Pending Owner)";
      bg = const Color(0xffE0E7FF);
      textCol = const Color(0xff4F46E5);
      icon = Icons.done;
    } else if (raw.contains('REJECT')) {
      label = "Rejected";
      bg = const Color(0xffFEE2E2);
      textCol = const Color(0xffDC2626);
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textCol.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textCol),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textCol,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
