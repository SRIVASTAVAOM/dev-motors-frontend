import 'package:flutter/material.dart';

class FloatingPillNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color? activeColor;

  const FloatingPillNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.activeColor,
  });
}

typedef PillNavItem = FloatingPillNavItem;

class FloatingPillNavBar extends StatelessWidget {
  final int? currentIndex;
  final Function(int)? onTap;
  final List<FloatingPillNavItem>? items;

  const FloatingPillNavBar({
    super.key,
    this.currentIndex,
    this.onTap,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    final List<FloatingPillNavItem> navItems = (items != null && items!.isNotEmpty)
        ? items!
        : const [
            FloatingPillNavItem(icon: Icons.approval, label: 'Claims'),
            FloatingPillNavItem(icon: Icons.bar_chart, label: 'Reports'),
            FloatingPillNavItem(icon: Icons.person, label: 'Profile'),
          ];

    final int rawIdx = currentIndex ?? 0;
    final int safeIndex = (rawIdx < 0 || rawIdx >= navItems.length) ? 0 : rawIdx;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < navItems.length; i++)
              _buildNavItem(navItems[i], i, safeIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(FloatingPillNavItem item, int idx, int activeIdx) {
    final bool isSelected = (idx == activeIdx);
    final Color primaryCol = item.activeColor ?? const Color(0xff2563EB);

    return InkWell(
      onTap: () {
        if (onTap != null) onTap!(idx);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryCol.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? (item.activeIcon ?? item.icon) : item.icon,
              size: 20,
              color: isSelected ? primaryCol : Colors.grey,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryCol,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
