import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../approvals/presentation/pages/manager_approvals_page.dart';

class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider();
    final user = auth.user;

    final managerName =
        user?["name"]?.toString() ?? "Manager";

    final location = user?["location"];

    final locationName =
        location is Map
            ? location["name"]?.toString() ?? "No Location Assigned"
            : "No Location Assigned";

    final locationCode =
        location is Map
            ? location["locationCode"]?.toString() ?? ""
            : "";

    final locationDisplay =
        locationCode.isNotEmpty
            ? "$locationName ($locationCode)"
            : locationName;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      drawer: _buildDrawer(
        context,
        auth: AuthProvider(),
        managerName: managerName,
        locationDisplay: locationDisplay,
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          "Manager Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.expenses,
          );
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text("Team Expenses"),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: "Expenses",
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: "Reports",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(
                managerName: managerName,
                locationDisplay: locationDisplay,
              ),

              const SizedBox(height: 25),

              _buildSummaryCards(),

              const SizedBox(height: 35),

              const Text(
                "Manager Actions",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManagerApprovalsPage(
                          auth: AuthProvider(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.approval),
                  label: const Text("Pending Approvals"),
                ),
              ),

              const SizedBox(height: 18),

              _buildActionGrid(context, auth),

              const SizedBox(height: 35),

              const Text(
                "Today's Team Expenses",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              _expenseTile(
                context,
                employee: "Rahul Sharma",
                category: "Fuel Cost",
                amount: "₹2,500",
                status: "Pending",
                statusColor: Colors.orange,
              ),

              _expenseTile(
                context,
                employee: "Amit Kumar",
                category: "Refreshments",
                amount: "₹450",
                status: "Approved",
                statusColor: Colors.green,
              ),

              _expenseTile(
                context,
                employee: "Priya Singh",
                category: "Conveyance",
                amount: "₹1,200",
                status: "Pending",
                statusColor: Colors.orange,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // WELCOME
  // ----------------------------------------------------------

  Widget _buildWelcomeSection({
    required String managerName,
    required String locationDisplay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Good Morning",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          managerName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          "$locationDisplay • Team Expense Overview",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // SUMMARY CARDS
  // ----------------------------------------------------------

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        final cards = [
          _summaryCard(
            title: "Today's Expense",
            amount: "₹18,450",
            icon: Icons.today,
            color: Colors.blue,
          ),
          _summaryCard(
            title: "Monthly Expense",
            amount: "₹4,86,250",
            icon: Icons.calendar_month,
            color: Colors.green,
          ),
          _summaryCard(
            title: "Pending",
            amount: "12",
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
          _summaryCard(
            title: "Team Members",
            amount: "8",
            icon: Icons.people,
            color: Colors.purple,
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(height: 13),

          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            amount,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // MANAGER ACTIONS
  // ----------------------------------------------------------

  Widget _buildActionGrid(BuildContext context, AuthProvider auth) {
    final actions = [
      _ActionData(
        title: "Team Expenses",
        subtitle: "View team expense records",
        icon: Icons.groups,
        color: Colors.blue,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.expenses,
          );
        },
      ),
      _ActionData(
        title: "Pending Approvals",
        subtitle: "Review pending expenses",
        icon: Icons.pending_actions,
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManagerApprovalsPage(
                auth: AuthProvider(),
              ),
            ),
          );
        },
      ),
      _ActionData(
        title: "Approved Expenses",
        subtitle: "View approved expenses",
        icon: Icons.check_circle_outline,
        color: Colors.green,
        onTap: () {
          _showComingSoon(
            context,
            "Approved Expenses",
          );
        },
      ),
      _ActionData(
        title: "Reports",
        subtitle: "View location reports",
        icon: Icons.bar_chart,
        color: Colors.purple,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.reports,
          );
        },
      ),
      _ActionData(
        title: "Notifications",
        subtitle: "View team notifications",
        icon: Icons.notifications_none,
        color: Colors.deepOrange,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.notifications,
          );
        },
      ),
      _ActionData(
        title: "Settings",
        subtitle: "Manage application settings",
        icon: Icons.settings_outlined,
        color: Colors.grey,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.settings,
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth < 600 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: action.onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor:
                          action.color.withValues(alpha: 0.12),
                      child: Icon(
                        action.icon,
                        color: action.color,
                        size: 27,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      action.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      action.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------
  // EXPENSE TILE
  // ----------------------------------------------------------

  Widget _expenseTile(
    BuildContext context, {
    required String employee,
    required String category,
    required String amount,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(
            Icons.receipt_long,
            color: Colors.blue,
          ),
        ),
        title: Text(
          employee,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(category),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.expenseDetails,
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // DRAWER
  // ----------------------------------------------------------

  Widget _buildDrawer(
    BuildContext context, {
    required AuthProvider auth,
    required String managerName,
    required String locationDisplay,
  }) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xff2563EB),
              child: Icon(
                Icons.manage_accounts,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              managerName,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              locationDisplay,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const Divider(height: 35),

            _drawerTile(
              context,
              icon: Icons.dashboard,
              title: "Dashboard",
              onTap: () {
                Navigator.pop(context);
              },
            ),

            _drawerTile(
              context,
              icon: Icons.groups,
              title: "Team Expenses",
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.expenses,
                );
              },
            ),

            _drawerTile(
              context,
              icon: Icons.pending_actions,
              title: "Pending Approvals",
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManagerApprovalsPage(
                      auth: AuthProvider(),
                    ),
                  ),
                );
              },
            ),

            _drawerTile(
              context,
              icon: Icons.check_circle_outline,
              title: "Approved Expenses",
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(
                  context,
                  "Approved Expenses",
                );
              },
            ),

            _drawerTile(
              context,
              icon: Icons.bar_chart,
              title: "Reports",
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.reports,
                );
              },
            ),

            _drawerTile(
              context,
              icon: Icons.notifications_none,
              title: "Notifications",
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.notifications,
                );
              },
            ),

            _drawerTile(
              context,
              icon: Icons.person_outline,
              title: "Profile",
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.profile,
                );
              },
            ),

            _drawerTile(
              context,
              icon: Icons.settings_outlined,
              title: "Settings",
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.settings,
                );
              },
            ),

            const Spacer(),

            const Divider(),

            _drawerTile(
              context,
              icon: Icons.logout,
              title: "Logout",
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blue,
      ),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showComingSoon(
    BuildContext context,
    String title,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$title module will be connected with backend.",
        ),
      ),
    );
  }
}

class _ActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}