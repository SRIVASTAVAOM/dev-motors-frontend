import 'package:flutter/material.dart';

class ExpenseDetailsSheet extends StatelessWidget {
  final dynamic item;

  const ExpenseDetailsSheet({super.key, required this.item});

  static void show(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseDetailsSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] ?? 'PENDING_MANAGER').toString().toUpperCase();
    final empName = item['employee']?['name'] ?? 'Staff Member';
    final empId = item['employee']?['employeeId'] ?? 'EMP001';
    final cat = item['category']?['name'] ?? item['categoryId'] ?? 'Operational';
    final desc = item['description'] ?? 'Expense';
    final amt = item['amount'] ?? '0';
    final city = item['location']?['city'] ?? 'Branch';

    int currentStep = 0;
    String statusReadable = "Waiting for Manager Approval";
    Color statusColor = Colors.orange;

        if (status == 'PENDING_MANAGER' || status == 'PENDING') {
      currentStep = 0;
      statusReadable = "Waiting for Manager Review";
      statusColor = Colors.orange;
    } else if (status == 'PENDING_OWNER' || status == 'APPROVED_1') {
      currentStep = 1;
      statusReadable = "Approved by Manager • Waiting for Owner Sign-off";
      statusColor = const Color(0xff4F46E5);
    } else if (status == 'PENDING_CASHIER' || status == 'APPROVED_2') {
      currentStep = 2;
      statusReadable = "Approved by Owner • Ready for Cashier Payout";
      statusColor = Colors.teal;
    } else if (status == 'PAID' || status == 'APPROVED') {
      currentStep = 3;
      statusReadable = "Paid & Disbursed by Cashier";
      statusColor = Colors.green;
    } else if (status == 'REJECTED') {
      currentStep = -1;
      statusReadable = "Expense Claim Rejected";
      statusColor = Colors.red;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(desc, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('$cat • $city Dealership', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
              Text('₹$amt', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff2563EB))),
            ],
          ),
          const SizedBox(height: 14),

          // Status Alert Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusReadable,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4-Step Pipeline Bar
          const Text('Approval Pipeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                _buildStepNode('1. Submitted', currentStep >= 0),
                _buildStepLine(currentStep >= 1),
                _buildStepNode('2. Manager', currentStep >= 1),
                _buildStepLine(currentStep >= 2),
                _buildStepNode('3. Cashier', currentStep >= 2),
                _buildStepLine(currentStep >= 3),
                _buildStepNode('4. Director', currentStep >= 3),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Staff Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xff2563EB),
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(empName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Employee ID: $empId • Location: $city', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bill Viewer Card (Tap to View)
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Verified Bill Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.blue.shade700),
                              const SizedBox(height: 12),
                              Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('₹$amt • Attached by $empName', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Chip(
                                label: Text('Tax Invoice Verified', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.receipt_long, color: Color(0xff2563EB)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('bill_receipt_proof.jpg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Tap to view attached invoice', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ],
                    ),
                  ),
                  Icon(Icons.zoom_in, color: Color(0xff2563EB), size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStepNode(String label, bool isDone) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isDone ? Colors.green : Colors.grey.shade300,
            child: Icon(isDone ? Icons.check : Icons.circle, size: 14, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
              color: isDone ? Colors.green.shade800 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isDone) {
    return Container(
      width: 14,
      height: 2,
      color: isDone ? Colors.green : Colors.grey.shade300,
    );
  }
}
