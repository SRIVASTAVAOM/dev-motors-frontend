import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      drawer: _buildDrawer(context),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          "Admin Dashboard",
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
        label: const Text("All Expenses"),
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
              _buildWelcomeSection(),

              const SizedBox(height: 25),

              _buildSummaryCards(),

              const SizedBox(height: 35),

              const Text(
                "Administration",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              _buildActionGrid(context),

              const SizedBox(height: 35),

              const Text(
                "Location-wise Expenses",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              _locationTile(
                context,
                "Location 01",
                "₹12,500",
              ),
              _locationTile(
                context,
                "Location 02",
                "₹8,450",
              ),
              _locationTile(
                context,
                "Location 03",
                "₹15,200",
              ),
              _locationTile(
                context,
                "Location 04",
                "₹9,850",
              ),
              _locationTile(
                context,
                "Location 05",
                "₹18,450",
              ),

              const SizedBox(height: 35),

              const Text(
                "Category-wise Expenses",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              _categoryTile("Fuel Cost", "₹45,600"),
              _categoryTile("Conveyance", "₹32,500"),
              _categoryTile("Refreshments", "₹18,200"),
              _categoryTile("Stationery", "₹12,450"),
              _categoryTile(
                "Customer Appeasement",
                "₹25,000",
              ),
              _categoryTile("Gifts", "₹8,500"),
              _categoryTile("Miscellaneous", "₹10,310"),

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

  Widget _buildWelcomeSection() {
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

        const Text(
          "Admin",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          "Dev Motors Pvt Ltd • Company Overview",
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
            title: "Today's Total",
            amount: "₹1,42,560",
            icon: Icons.today,
            color: Colors.blue,
          ),
          _summaryCard(
            title: "Monthly Total",
            amount: "₹24,86,450",
            icon: Icons.calendar_month,
            color: Colors.green,
          ),
          _summaryCard(
            title: "Locations",
            amount: "18",
            icon: Icons.location_on,
            color: Colors.orange,
          ),
          _summaryCard(
            title: "Employees",
            amount: "45",
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
  // ADMIN ACTIONS
  // ----------------------------------------------------------

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      _ActionData(
        title: "All Expenses",
        subtitle: "View company expenses",
        icon: Icons.receipt_long,
        color: Colors.blue,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.expenses,
          );
        },
      ),
      _ActionData(
        title: "Pending Expenses",
        subtitle: "Review pending expenses",
        icon: Icons.pending_actions,
        color: Colors.orange,
        onTap: () {
          _showComingSoon(
            context,
            "Pending Expenses",
          );
        },
      ),
      _ActionData(
        title: "Employees",
        subtitle: "Manage 45 employees",
        icon: Icons.people,
        color: Colors.green,
        onTap: () {
          _showComingSoon(
            context,
            "Employees",
          );
        },
      ),
      _ActionData(
        title: "Managers",
        subtitle: "Manage managers",
        icon: Icons.manage_accounts,
        color: Colors.purple,
        onTap: () {
          _showComingSoon(
            context,
            "Managers",
          );
        },
      ),
      _ActionData(
        title: "Locations",
        subtitle: "Manage 18 locations",
        icon: Icons.location_on,
        color: Colors.red,
        onTap: () {
          _showComingSoon(
            context,
            "Locations",
          );
        },
      ),
      _ActionData(
        title: "Reports",
        subtitle: "Company-wide reports",
        icon: Icons.bar_chart,
        color: Colors.indigo,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.reports,
          );
        },
      ),
      _ActionData(
        title: "Notifications",
        subtitle: "View company notifications",
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
            constraints.maxWidth < 600 ? 2 : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: action.onTap,
              child: Container(
                padding: const EdgeInsets.all(14),
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
  // LOCATION TILE
  // ----------------------------------------------------------

  Widget _locationTile(
    BuildContext context,
    String location,
    String amount,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
          ),
        ),
        title: Text(
          location,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          "Daily expense",
        ),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () {
          _showComingSoon(
            context,
            "$location details",
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // CATEGORY TILE
  // ----------------------------------------------------------

  Widget _categoryTile(
    String category,
    String amount,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xffEFF6FF),
          child: Icon(
            Icons.receipt_long,
            color: Colors.blue,
          ),
        ),
        title: Text(
          category,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // DRAWER
  // ----------------------------------------------------------

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xff2563EB),
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              "Administrator",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "Dev Motors Pvt Ltd",
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
              icon: Icons.receipt_long,
              title: "All Expenses",
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
              title: "Pending Expenses",
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(
                  context,
                  "Pending Expenses",
                );
              },
            ),

            _drawerTile(
              context,
              icon: Icons.people,
              title: "Employees",
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(
                  context,
                  "Employees",
                );
              },
            ),

            _drawerTile(
              context,
              icon: Icons.manage_accounts,
              title: "Managers",
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(
                  context,
                  "Managers",
                );
              },
            ),

            _drawerTile(
              context,
              icon: Icons.location_on,
              title: "Locations",
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(
                  context,
                  "Locations",
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