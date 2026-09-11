import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import 'quick_action_card.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            QuickActionCard(
              title: "Add Expense",
              icon: Icons.add_circle_outline,
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.addExpense,
                );
              },
            ),

            QuickActionCard(
              title: "Reports",
              icon: Icons.bar_chart,
              color: Colors.green,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.reports,
                );
              },
            ),

            QuickActionCard(
              title: "Notifications",
              icon: Icons.notifications_none,
              color: Colors.orange,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.notifications,
                );
              },
            ),

            QuickActionCard(
              title: "Profile",
              icon: Icons.person_outline,
              color: Colors.purple,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.profile,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}