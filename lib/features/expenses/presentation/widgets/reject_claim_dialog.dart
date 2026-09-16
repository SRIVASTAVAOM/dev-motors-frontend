import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class RejectClaimDialog extends StatefulWidget {
  final String expenseId;
  final Function(String reason) onConfirm;

  const RejectClaimDialog({
    super.key,
    required this.expenseId,
    required this.onConfirm,
  });

  @override
  State<RejectClaimDialog> createState() => _RejectClaimDialogState();
}

class _RejectClaimDialogState extends State<RejectClaimDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.danger, size: 22),
          SizedBox(width: 8),
          Text(
            "Reject Claim",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Please state the business reason for rejecting this claim. The employee will be notified immediately.",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Enter rejection reason (e.g. invalid bill date, exceeds policy limit...)",
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size(140, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final reason = _reasonController.text.trim();
            if (reason.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please provide a reason for rejection")),
              );
              return;
            }
            Navigator.pop(context);
            widget.onConfirm(reason);
          },
          child: const Text("Confirm Rejection", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
