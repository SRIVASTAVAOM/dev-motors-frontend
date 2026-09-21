import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/services/api_service.dart';

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({super.key});

  void _navigate(
    BuildContext context,
    String route,
  ) {
    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      Navigator.of(context).pushNamed(route);
    });
  }

  Widget tile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────
            // PROFILE HEADER
            // ─────────────────────────────

            const SizedBox(height: 25),

            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xff2563EB),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 42,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              "Rahul Sharma",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              "Sales Executive",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),

            const Divider(
              height: 1,
            ),

            const SizedBox(height: 12),

            // ─────────────────────────────
            // MAIN MENU
            // ─────────────────────────────

            tile(
              context: context,
              icon: Icons.dashboard,
              title: "Dashboard",
              onTap: () {
                Navigator.of(context).pop();
              },
            ),

            tile(
              context: context,
              icon: Icons.receipt_long,
              title: "Expenses",
              onTap: () {
                _navigate(
                  context,
                  AppRoutes.expenses,
                );
              },
            ),

            tile(
              context: context,
              icon: Icons.bar_chart,
              title: "Reports",
              onTap: () {
                _navigate(
                  context,
                  AppRoutes.reports,
                );
              },
            ),

            tile(
              context: context,
              icon: Icons.notifications,
              title: "Notifications",
              onTap: () {
                _navigate(
                  context,
                  AppRoutes.notifications,
                );
              },
            ),

            tile(
              context: context,
              icon: Icons.person,
              title: "Profile",
              onTap: () {
                _navigate(
                  context,
                  AppRoutes.profile,
                );
              },
            ),

            tile(
              context: context,
              icon: Icons.settings,
              title: "Settings",
              onTap: () {
                _navigate(
                  context,
                  AppRoutes.settings,
                );
              },
            ),

            const Spacer(),

            // ─────────────────────────────
            // LOGOUT
            // ─────────────────────────────

            const Divider(
              height: 1,
            ),

            const SizedBox(height: 8),

            tile(
              context: context,
              icon: Icons.logout,
              title: "Logout",
              color: Colors.red,
              onTap: () async {
                Navigator.of(context).pop();
                await ApiService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}