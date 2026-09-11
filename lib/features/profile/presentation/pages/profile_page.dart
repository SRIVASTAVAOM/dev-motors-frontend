import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../widgets/profile_action_tile.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_tile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),

      body: Center(
        child: SizedBox(
          width: isDesktop ? 700 : double.infinity,

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                const ProfileHeader(),

                const SizedBox(height: 25),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Employee Information",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                const ProfileInfoTile(
                  icon: Icons.badge,
                  title: "Employee ID",
                  value: "EMP-1001",
                ),

                const ProfileInfoTile(
                  icon: Icons.email,
                  title: "Email",
                  value: "rahul@devmotors.com",
                ),

                const ProfileInfoTile(
                  icon: Icons.phone,
                  title: "Phone",
                  value: "+91 9876543210",
                ),

                const ProfileInfoTile(
                  icon: Icons.business,
                  title: "Department",
                  value: "Sales",
                ),

                const ProfileInfoTile(
                  icon: Icons.location_on,
                  title: "Location",
                  value: "Kanpur",
                ),

                const SizedBox(height: 30),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Actions",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                ProfileActionTile(
                  icon: Icons.edit,
                  title: "Edit Profile",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.editProfile,
                    );
                  },
                ),

                ProfileActionTile(
                icon: Icons.lock_outline,
                title: "Change Password",
                color: Colors.orange,
                onTap: () {
                Navigator.pushNamed(
                context,
                AppRoutes.changePassword,
                );
                },
              ),

                ProfileActionTile(
                  icon: Icons.logout,
                  title: "Logout",
                  color: Colors.red,
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}