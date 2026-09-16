import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../profile/presentation/widgets/change_password_dialog.dart';
import 'add_staff_dialog.dart';

class UnifiedExecutiveHeader extends StatelessWidget {
  final String role; // 'OWNER', 'MANAGER', 'CASHIER', 'EMPLOYEE'
  final String userName;
  final String userOccupation;
  final String userBranch;
  final List<dynamic> expenses;
  final List<Map<String, dynamic>> serverNotifications;
  final VoidCallback onRefresh;
  final Future<void> Function()? onExportCsv;

  const UnifiedExecutiveHeader({
    super.key,
    required this.role,
    required this.userName,
    required this.userOccupation,
    required this.userBranch,
    required this.expenses,
    this.serverNotifications = const [],
    required this.onRefresh,
    this.onExportCsv,
  });

  IconData _getRoleIcon() {
    switch (role.toUpperCase()) {
      case 'OWNER':
      case 'ADMIN':
        return Icons.shield;
      case 'MANAGER':
        return Icons.verified_user_outlined;
      case 'CASHIER':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Color _getRoleColor() {
    switch (role.toUpperCase()) {
      case 'OWNER':
      case 'ADMIN':
        return AppColors.warning;
      case 'MANAGER':
        return AppColors.purple;
      case 'CASHIER':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  Color _getRoleBgColor() {
    switch (role.toUpperCase()) {
      case 'OWNER':
      case 'ADMIN':
        return AppColors.warningLight;
      case 'MANAGER':
        return AppColors.purpleLight;
      case 'CASHIER':
        return AppColors.infoLight;
      default:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor();
    final roleBg = _getRoleBgColor();
    final isOwner = role.toUpperCase() == 'OWNER' || role.toUpperCase() == 'ADMIN';

    final notifs = NotificationService.getNotificationsForRole(
      role.toUpperCase(),
      expenses,
      userBranch: userBranch,
      currentUser: ApiService.currentUser,
      serverNotifications: serverNotifications,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: roleBg,
            child: Icon(_getRoleIcon(), color: roleColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: roleBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOwner ? Icons.workspace_premium : Icons.badge_outlined,
                            size: 11,
                            color: roleColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            userOccupation,
                            style: TextStyle(
                              fontSize: 11,
                              color: roleColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.business_outlined, size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            userBranch,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xff475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: "Notifications",
                icon: const Icon(Icons.notifications_none, color: AppColors.textSecondary),
                onPressed: () => NotificationService.showNotificationSheet(
                  context,
                  role.toUpperCase(),
                  expenses,
                  onRefresh,
                  currentUser: ApiService.currentUser,
                  userBranch: userBranch,
                  serverNotifications: serverNotifications,
                ),
              ),
              if (notifs.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        "${notifs.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            tooltip: "More Options",
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) async {
              if (val == 'add_staff') {
                showDialog(
                  context: context,
                  builder: (_) => AddStaffDialog(onStaffCreated: onRefresh),
                );
              } else if (val == 'export_csv') {
                if (onExportCsv != null) {
                  await onExportCsv!();
                }
              } else if (val == 'change_password') {
                showDialog(
                  context: context,
                  builder: (_) => const ChangePasswordDialog(),
                );
              } else if (val == 'refresh') {
                onRefresh();
              } else if (val == 'logout') {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            itemBuilder: (ctx) => [
              if (isOwner)
                const PopupMenuItem(
                  value: 'add_staff',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_alt_1, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text("Add New Staff", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              if (onExportCsv != null)
                const PopupMenuItem(
                  value: 'export_csv',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 18, color: Color(0xffEA580C)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text("Export Ledger (CSV)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text("Change Password", style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text("Refresh Data", style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text("Log Out", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
