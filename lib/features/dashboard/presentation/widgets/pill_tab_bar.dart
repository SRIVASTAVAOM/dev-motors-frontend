import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PillTabItem {
  final String label;
  final int count;
  final IconData icon;

  const PillTabItem({
    required this.label,
    required this.count,
    required this.icon,
  });
}

class PillTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<PillTabItem> tabs;
  final ValueChanged<int> onTabSelected;

  const PillTabBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = selectedIndex == idx;
          final tab = tabs[idx];

          return Expanded(
            child: InkWell(
              onTap: () => onTabSelected(idx),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      size: 15,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        "${tab.label} (${tab.count})",
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 12,
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
