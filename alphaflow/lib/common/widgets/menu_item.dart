import 'package:flutter/material.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';

/// Premium menu item widget for the AlphaFlow drawer
class MenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;

  const MenuItem({
    super.key,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: selected ? AlphaFlowTheme.textPrimary : AlphaFlowTheme.textSecondary,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: selected ? AlphaFlowTheme.textPrimary : AlphaFlowTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Sora',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header for menu groups
class MenuSectionHeader extends StatelessWidget {
  final String title;

  const MenuSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF888888),
          fontWeight: FontWeight.w500,
          fontFamily: 'Sora',
        ),
      ),
    );
  }
} 