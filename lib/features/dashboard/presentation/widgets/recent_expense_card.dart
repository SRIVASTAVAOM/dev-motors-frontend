import 'package:flutter/material.dart';

class RecentExpenseCard extends StatelessWidget {
  final String category;
  final String amount;
  final String date;
  final String status;

  const RecentExpenseCard({
    super.key,
    required this.category,
    required this.amount,
    required this.date,
    this.status = 'PENDING_MANAGER',
  });

  Widget _buildLiveTaskBar(String statusVal) {
    final s = statusVal.toUpperCase().trim();
    int currentStep = 1; // 1: Submitted, 2: Manager, 3: Owner, 4: Paid
    if (s.contains('PAID') || s.contains('DISBURSED')) {
      currentStep = 4;
    } else if (s.contains('PENDING_CASHIER') || s.contains('APPROVED_2') || s.contains('OWNER_APPROVED')) {
      currentStep = 3;
    } else if (s.contains('PENDING_OWNER') || s.contains('APPROVED_1') || s.contains('MANAGER_APPROVED')) {
      currentStep = 2;
    } else {
      currentStep = 1;
    }

    Widget buildNode(String title, bool active, bool current) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFF10B981) : Colors.grey.shade300,
              border: current ? Border.all(color: const Color(0xFF3B82F6), width: 2) : null,
            ),
            child: Center(
              child: active
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Text(title.substring(0, 1), style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: current ? FontWeight.bold : FontWeight.normal,
              color: active ? const Color(0xFF10B981) : Colors.grey.shade600,
            ),
          )
        ],
      );
    }

    Widget buildLine(bool active) {
      return Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 14),
          color: active ? const Color(0xFF10B981) : Colors.grey.shade300,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          buildNode("1. Emp", currentStep >= 1, currentStep == 1),
          buildLine(currentStep >= 2),
          buildNode("2. Mgr", currentStep >= 2, currentStep == 2),
          buildLine(currentStep >= 3),
          buildNode("3. Own", currentStep >= 3, currentStep == 3),
          buildLine(currentStep >= 4),
          buildNode("4. Paid", currentStep >= 4, currentStep == 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade50,
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '₹$amount',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981)),
              ),
            ],
          ),
          _buildLiveTaskBar(status),
        ],
      ),
    );
  }
}
