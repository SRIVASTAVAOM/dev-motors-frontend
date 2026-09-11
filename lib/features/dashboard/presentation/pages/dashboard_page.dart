import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';

import '../widgets/dashboard_drawer.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_summary.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_recent.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      drawer: const DashboardDrawer(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.addExpense,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Expense"),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,

        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break;

            case 1:
              Navigator.pushNamed(
                context,
                AppRoutes.expenses,
              );
              break;

            case 2:
              Navigator.pushNamed(
                context,
                AppRoutes.reports,
              );
              break;

            case 3:
              Navigator.pushNamed(
                context,
                AppRoutes.profile,
              );
              break;
          }
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: "Expenses",
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: "Reports",
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),

      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(),

              SizedBox(height: 30),

              DashboardSummary(),

              SizedBox(height: 35),

              DashboardQuickActions(),

              SizedBox(height: 35),

              DashboardRecent(),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}