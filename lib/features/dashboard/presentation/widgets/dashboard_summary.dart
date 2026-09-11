import 'package:flutter/material.dart';

import 'summary_card.dart';

class DashboardSummary extends StatelessWidget {
  const DashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        MediaQuery.of(context).size.width < 700;

    if (isMobile) {
      return const Column(
        children: [
          SummaryCard(
            title: "Today's Expense",
            amount: "₹8,560",
            icon: Icons.today,
          ),

          SizedBox(height: 16),

          SummaryCard(
            title: "Monthly Expense",
            amount: "₹2,36,000",
            icon: Icons.calendar_month,
          ),
        ],
      );
    }

    return const Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: "Today's Expense",
            amount: "₹8,560",
            icon: Icons.today,
          ),
        ),

        SizedBox(width: 16),

        Expanded(
          child: SummaryCard(
            title: "Monthly Expense",
            amount: "₹2,36,000",
            icon: Icons.calendar_month,
          ),
        ),
      ],
    );
  }
}