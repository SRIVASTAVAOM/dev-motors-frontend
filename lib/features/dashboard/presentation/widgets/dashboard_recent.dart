import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import 'recent_expense_card.dart';

class DashboardRecent extends StatelessWidget {
  const DashboardRecent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Expenses",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.expenseDetails,
            );
          },
          child: const RecentExpenseCard(
            category: "Fuel",
            amount: "₹2,500",
            date: "Today",
          ),
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.expenseDetails,
            );
          },
          child: const RecentExpenseCard(
            category: "Refreshments",
            amount: "₹450",
            date: "Today",
          ),
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.expenseDetails,
            );
          },
          child: const RecentExpenseCard(
            category: "Stationery",
            amount: "₹680",
            date: "Yesterday",
          ),
        ),
      ],
    );
  }
}