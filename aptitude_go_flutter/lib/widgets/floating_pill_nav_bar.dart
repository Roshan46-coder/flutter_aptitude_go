import 'package:flutter/material.dart';
import '../core/theme.dart';

class FloatingPillNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const FloatingPillNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class FloatingPillNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingPillNavItem> items;

  const FloatingPillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final activeColor = AppTheme.neonPurple;
    final inactiveColor = isDark ? Colors.white38 : Colors.black45;
    final surfaceColor = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF2F2F7);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset > 0 ? bottomInset + 10 : 14),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? activeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              key: ValueKey('$index-icon-${isSelected ? 'a' : 'i'}'),
                              color: isSelected ? Colors.white : inactiveColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? activeColor : inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
