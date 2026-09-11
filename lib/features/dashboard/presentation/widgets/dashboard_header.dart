import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),

        const SizedBox(width: 10),

        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xff2563EB),
          child: Icon(
            Icons.person,
            color: Colors.white,
          ),
        ),

        const SizedBox(width: 15),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Good Morning",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              SizedBox(height: 4),

              Text(
                "Rahul Sharma",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),

        // Notifications
        IconButton(
          tooltip: "Notifications",
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.notifications,
            );
          },
          icon: const Icon(
            Icons.notifications_none,
          ),
        ),
      ],
    );
  }
}