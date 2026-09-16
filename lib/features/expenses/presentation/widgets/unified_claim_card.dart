import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/claim_workflow_engine.dart';
import '../../../../core/utils/safe_parser.dart';
import 'approval_stepper.dart';
import 'receipt_viewer_dialog.dart';

class UnifiedClaimCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final String userBranch;
  final bool isOwnClaim;
  final bool canEdit;
  final bool canDelete;
  final bool canApprove;
  final bool canReject;
  final bool canPay;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onPay;

  const UnifiedClaimCard({
    super.key,
    required this.expense,
    required this.userBranch,
    this.isOwnClaim = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canApprove = false,
    this.canReject = false,
    this.canPay = false,
    this.onEdit,
    this.onDelete,
    this.onApprove,
    this.onReject,
    this.onPay,
  });

  String _getString(dynamic val, [String fallback = '']) => SafeParser.getString(val, fallback);
  double _getDouble(dynamic val) => SafeParser.getDouble(val);

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('fuel') || cat.contains('petrol') || cat.contains('diesel')) {
      return Icons.local_gas_station_rounded;
    } else if (cat.contains('maintenance') || cat.contains('repair') || cat.contains('wash')) {
      return Icons.car_repair_rounded;
    } else if (cat.contains('travel') || cat.contains('transit') || cat.contains('toll')) {
      return Icons.commute_rounded;
    } else if (cat.contains('food') || cat.contains('meal') || cat.contains('refreshment') || cat.contains('tea')) {
      return Icons.restaurant_rounded;
    } else if (cat.contains('office') || cat.contains('stationery')) {
      return Icons.inventory_2_rounded;
    } else if (cat.contains('marketing') || cat.contains('promo')) {
      return Icons.campaign_rounded;
    } else if (cat.contains('incentive')) {
      return Icons.military_tech_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final id = _getString(expense['id']).isNotEmpty ? _getString(expense['id']) : _getString(expense['_id']);

    final rawStatus = expense['status'];
    final String statusStr = (rawStatus is Map)
        ? (rawStatus['name'] ?? rawStatus['status'] ?? 'PENDING').toString()
        : (rawStatus?.toString() ?? 'PENDING');

    final rawReceipt = expense['receiptImage'] ?? expense['receiptUrl'] ?? '';
    final receiptData = (rawReceipt is Map) ? '' : rawReceipt.toString();
    final hasReceipt = receiptData.trim().isNotEmpty && receiptData != 'null';

    final category = _getString(expense['category'], 'General');
    final description = _getString(expense['description'], 'Expense Claim');
    final amount = _getDouble(expense['amount']);

    final creatorRole = isOwnClaim ? 'MANAGER' : ClaimWorkflowEngine.extractCreatorRole(expense);
    final creatorName = isOwnClaim
        ? 'My Expense'
        : _getString(
            expense['employee'] is Map
                ? expense['employee']['name']
                : (expense['employeeName'] ?? expense['userName']),
            'Staff',
          );
    final location = _getString(
      expense['location'] is Map ? expense['location']['name'] : (expense['location'] ?? expense['branch']),
      userBranch,
    );

    final statusColor = AppColors.getStatusColor(statusStr);
    final statusBg = AppColors.getStatusLightBg(statusStr);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category icon, Description, Subtitle, and Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "$creatorName ($creatorRole) • $category • $location",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${amount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.slateDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: Text(
                      statusStr.replaceAll('_', ' '),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stepper
          ApprovalStepper(
            status: statusStr,
            rejectionReason: ClaimWorkflowEngine.getRejectionRemark(id, expense),
            creatorRole: creatorRole,
            expense: expense,
          ),

          // Attached Receipt preview button
          if (hasReceipt) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => showDialog(
                context: context,
                builder: (_) => ReceiptViewerDialog(
                  receiptData: receiptData,
                  title: description,
                ),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.infoBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attachment_rounded, size: 15, color: AppColors.info),
                    SizedBox(width: 5),
                    Text(
                      "View Attached Receipt / Bill",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.info,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new, size: 13, color: AppColors.info),
                  ],
                ),
              ),
            ),
          ],

          // Action Row for Employee Edit/Delete
          if (canEdit || canDelete) ...[
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canEdit && onEdit != null)
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 14, color: AppColors.info),
                          SizedBox(width: 4),
                          Text(
                            "Edit & Receipt",
                            style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (canDelete && onDelete != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, size: 14, color: AppColors.danger),
                          SizedBox(width: 4),
                          Text(
                            "Delete",
                            style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Action Row for Manager/Owner Approve & Reject
          if (canApprove || canReject) ...[
            const Divider(height: 22),
            Row(
              children: [
                if (canReject && onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onReject,
                      child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (canReject && canApprove) const SizedBox(width: 12),
                if (canApprove && onApprove != null)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onApprove,
                      child: const Text("Accept & Forward", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ],

          // Action Row for Cashier Disburse / Pay
          if (canPay && onPay != null) ...[
            const Divider(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text(
                  "Mark Paid & Disburse Cash",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: onPay,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
