import 'package:flutter/material.dart';

class DepartmentBadge extends StatelessWidget {
  final String department;
  final bool isCompact;

  const DepartmentBadge({
    super.key,
    required this.department,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSales = department.trim().toLowerCase() == 'sales';

    final bg = isSales ? const Color(0xffEFF6FF) : const Color(0xffF0FDF4);
    final border = isSales ? const Color(0xffBFDBFE) : const Color(0xffBBF7D0);
    final text = isSales ? const Color(0xff1D4ED8) : const Color(0xff15803D);
    final icon = isSales ? Icons.storefront_rounded : Icons.build_rounded;
    final label = isSales ? 'Sales' : 'Service';

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: text),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: text,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: text,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
