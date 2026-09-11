import 'package:flutter/material.dart';

import '../widgets/notification_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final double contentWidth =
        screenWidth >= 900 ? 800 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        elevation: 0,
      ),

      body: Center(
        child: SizedBox(
          width: contentWidth,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Recent Notifications",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Stay updated with your expenses and account activity.",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              const NotificationCard(
                icon: Icons.check_circle,
                color: Colors.green,
                title: "Expense Approved",
                subtitle:
                    "Your fuel expense of ₹2,500 has been approved.",
                time: "2 min ago",
                unread: true,
              ),

              const NotificationCard(
                icon: Icons.schedule,
                color: Colors.orange,
                title: "Pending Approval",
                subtitle:
                    "Your refreshment expense is waiting for approval.",
                time: "20 min ago",
                unread: true,
              ),

              const NotificationCard(
                icon: Icons.cancel,
                color: Colors.red,
                title: "Expense Rejected",
                subtitle:
                    "Your stationery expense requires an updated receipt.",
                time: "Yesterday",
              ),

              const NotificationCard(
                icon: Icons.system_update_alt,
                color: Colors.blue,
                title: "System Update",
                subtitle:
                    "New expense categories are now available.",
                time: "Yesterday",
              ),

              const NotificationCard(
                icon: Icons.celebration,
                color: Colors.purple,
                title: "Welcome",
                subtitle:
                    "Welcome to Dev Motors Expense Management.",
                time: "2 days ago",
              ),
            ],
          ),
        ),
      ),
    );
  }
}