import 'package:flutter/material.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/widgets/profile_sheet.dart';
import 'notifications_sheet.dart';
import 'add_staff_dialog.dart';
import '../../../profile/presentation/widgets/change_password_dialog.dart';

class CustomDashboardHeader extends StatelessWidget {
  final String? title;
  final VoidCallback? onRefresh;
  final List<dynamic>? expenses;

  const CustomDashboardHeader({
    super.key,
    this.title,
    this.onRefresh,
    this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider();
    final user = auth.user;
    final role = (user?['role'] ?? auth.role ?? 'EMPLOYEE').toString().toUpperCase();
    final name = user?['name'] ?? auth.name ?? 'User';
    final rawLoc = user?['location'] ?? user?['branch'] ?? user?['branchName'];
    final location = (rawLoc is Map) 
        ? (rawLoc['name']?.toString() ?? rawLoc['branchName']?.toString() ?? 'Main Branch')
        : (rawLoc?.toString().isNotEmpty == true ? rawLoc.toString() : 'Main Branch');
    final isOwner = role == 'OWNER' || auth.employeeId == 'DEV_OWNER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar -> Opens Profile Sheet
          InkWell(
            onTap: () => ProfileSheet.show(context, onProfileUpdated: onRefresh),
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              backgroundColor: const Color(0xff2563EB).withValues(alpha: 0.1),
              radius: 20,
              backgroundImage: ImagePickerHelper.getAvatarImageProvider(
                (user?['avatarUrl'] ?? user?['profileImage'] ?? '').toString().trim(),
              ),
              child: ((user?['avatarUrl'] ?? user?['profileImage'] ?? '').toString().trim().isEmpty ||
                      ImagePickerHelper.getAvatarImageProvider(
                            (user?['avatarUrl'] ?? user?['profileImage'] ?? '').toString().trim(),
                          ) ==
                          null)
                  ? const Icon(Icons.person, color: Color(0xff2563EB))
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => ProfileSheet.show(context, onProfileUpdated: onRefresh),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOwner ? Colors.purple.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isOwner ? Colors.purple.shade200 : Colors.blue.shade200),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isOwner ? Colors.purple.shade700 : const Color(0xff2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Color(0xff64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 11, color: Color(0xff64748B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Owner-Only: Add Staff Button
          if (isOwner)
            Container(
              margin: const EdgeInsets.only(right: 6),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AddStaffDialog(onStaffCreated: () {
                      if (onRefresh != null) onRefresh!();
                    }),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text('Add Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),

          // Dedicated Change Password Button
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined, color: Color(0xff64748B)),
            tooltip: 'Change Password',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const ChangePasswordDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xff64748B)),
            tooltip: 'Notifications',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => NotificationsSheet(expenses: expenses ?? []),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xff64748B)),
            tooltip: 'Refresh',
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
