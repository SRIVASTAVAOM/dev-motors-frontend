import 'package:flutter/material.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class NotificationsSheet extends StatefulWidget {
  final List<dynamic> expenses;
  final VoidCallback? onClear;

  const NotificationsSheet({super.key, required this.expenses, this.onClear});

  static void show(BuildContext context, List<dynamic> expenses, {VoidCallback? onClear}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationsSheet(expenses: expenses, onClear: onClear),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  bool _cleared = false;

  @override
  Widget build(BuildContext context) {
    final role = AuthProvider().role ?? 'EMPLOYEE';

    List<Map<String, dynamic>> notifications = [];

    if (!_cleared) {
      for (var e in widget.expenses.take(12)) {
        final status = (e['status'] ?? 'PENDING_MANAGER').toString().toUpperCase();
        final empName = e['employee']?['name'] ?? 'Staff';
        final desc = e['description'] ?? 'Expense';
        final amt = e['amount'] ?? '0';

        if (role == 'MANAGER') {
          if (status == 'PENDING' || status == 'PENDING_MANAGER') {
            notifications.add({
              'title': 'Approval Required: ₹$amt',
              'desc': '$empName submitted $desc',
              'icon': Icons.pending_actions,
              'color': Colors.orange,
              'time': 'Action Needed',
            });
          }
        } else if (role == 'CASHIER') {
          if (status == 'APPROVED_2' || status == 'PENDING_CASHIER' || status == 'PENDING_FINANCE') {
            notifications.add({
              'title': 'Payout Pipeline: ₹$amt',
              'desc': '$empName • $desc (${status == 'PENDING_FINANCE' ? 'Approved by Manager' : 'Under Manager Review'})',
              'icon': Icons.payments_outlined,
              'color': Colors.teal,
              'time': status == 'PENDING_FINANCE' ? 'Ready to Disburse' : 'In Review',
            });
          }
        } else if (role == 'OWNER') {
          if (status == 'APPROVED_1' || status == 'PENDING_OWNER') {
            notifications.add({
              'title': 'Sign-off: ₹$amt',
              'desc': '$empName • $desc',
              'icon': Icons.shield_outlined,
              'color': const Color(0xff4F46E5),
              'time': 'Pipeline',
            });
          }
        } else {
          notifications.add({
            'title': '$desc (₹$amt)',
            'desc': 'Status: $status',
            'icon': status == 'PAID' ? Icons.check_circle : Icons.hourglass_top,
            'color': status == 'PAID' ? Colors.green : Colors.blue,
            'time': 'Update',
          });
        }
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dealership Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (notifications.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _cleared = true);
                    if (widget.onClear != null) {
                      widget.onClear!();
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications cleared!')),
                    );
                  },
                  icon: const Icon(Icons.clear_all, size: 18, color: Colors.red),
                  label: const Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('No unread alerts for your role.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final n = notifications[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: (n['color'] as Color).withValues(alpha: 0.12),
                          child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(n['desc'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(n['time'], style: TextStyle(color: n['color'] as Color, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
