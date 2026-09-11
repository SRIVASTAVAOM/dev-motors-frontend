import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../widgets/settings_tile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),

      body: Center(
        child: SizedBox(
          width: isDesktop ? 800 : double.infinity,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Account",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              SettingsTile(
                icon: Icons.person_outline,
                title: "Profile",
                subtitle: "Manage your profile information",
                color: Colors.blue,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.profile,
                  );
                },
              ),

              SettingsTile(
                icon: Icons.lock_outline,
                title: "Change Password",
                subtitle: "Update your account password",
                color: Colors.orange,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.changePassword,
                  );
                },
              ),

              const SizedBox(height: 25),

              const Text(
                "Preferences",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              SettingsTile(
                icon: Icons.notifications_none,
                title: "Notifications",
                subtitle: notificationsEnabled
                    ? "Notifications are enabled"
                    : "Notifications are disabled",
                color: Colors.green,
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),
              ),

              SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: "Dark Mode",
                subtitle: darkModeEnabled
                    ? "Dark mode enabled"
                    : "Light mode enabled",
                color: Colors.purple,
                trailing: Switch(
                  value: darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      darkModeEnabled = value;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          darkModeEnabled
                              ? "Dark mode selected"
                              : "Light mode selected",
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Support",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              SettingsTile(
                icon: Icons.help_outline,
                title: "Help & Support",
                subtitle: "Get help with the application",
                color: Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Help & Support coming soon",
                      ),
                    ),
                  );
                },
              ),

              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy Policy",
                subtitle: "View privacy information",
                color: Colors.teal,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Privacy Policy coming soon",
                      ),
                    ),
                  );
                },
              ),

              SettingsTile(
                icon: Icons.info_outline,
                title: "About",
                subtitle: "Dev Motors Expense Management",
                color: Colors.indigo,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName:
                        "Dev Motors Expense Management",
                    applicationVersion: "1.0.0",
                    applicationIcon: const Icon(
                      Icons.directions_car,
                      size: 40,
                    ),
                    children: const [
                      Text(
                        "Expense management application "
                        "for Dev Motors employees.",
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  label: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.red,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}