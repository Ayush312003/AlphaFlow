import 'package:flutter/material.dart';
import 'package:alphaflow/common/widgets/glassmorphic_components.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:intl/intl.dart';

/// Premium calendar strip with glassmorphic styling
class PremiumCalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onDateSelected;

  const PremiumCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.today,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Generate 7 days starting from 6 days ago
    final List<DateTime> weekDays = List.generate(7, (index) {
      return today.subtract(Duration(days: 6 - index));
    });

    return GlassmorphicComponents.calendarGlassmorphicCard(
      child: Column(
        children: [
          // Month name
          Text(
            DateFormat.yMMM().format(selectedDate),
            style: const TextStyle(
              color: AlphaFlowTheme.guidedTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'Sora',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Calendar days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((date) {
              final isSelected = _isSameDay(date, selectedDate);
              final isActive = _isSameDay(date, today);
              final dayName = DateFormat.E().format(date);
              final dayNumber = date.day.toString();
              
              return Column(
                children: [
                  // Day name
                  Text(
                    dayName,
                    style: const TextStyle(
                      color: AlphaFlowTheme.guidedTextSecondary,
                      fontSize: 12,
                      fontFamily: 'Sora',
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Day number
                  GlassmorphicComponents.calendarDay(
                    day: dayNumber,
                    isActive: isActive,
                    isSelected: isSelected,
                    onTap: () => onDateSelected(date),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
} 