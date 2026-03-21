import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/trade.dart';

/// A grid representing days of a specific month.
/// Success/Failure intensity is reflected in the cell background colors.
/// Allows for day selection to filter trade views in the parent screen.
class TradingHeatmap extends StatelessWidget {
  final List<Trade> trades;
  final DateTime viewMonth;
  final DateTime? selectedDate;
  final Function(DateTime) onDaySelected;

  const TradingHeatmap({
    super.key,
    required this.trades,
    required this.viewMonth,
    this.selectedDate,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Standard trading week days
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Determine the number of days in the requested viewMonth
    final daysInMonth = DateUtils.getDaysInMonth(viewMonth.year, viewMonth.month);
    
    // Determine the first day of the week for this month to align the grid (0 = Monday, 6 = Sunday)
    // Note: DateTime.weekday returns 1=Mon...7=Sun
    final firstWeekday = DateTime(viewMonth.year, viewMonth.month, 1).weekday - 1;

    // Map profit levels for each day of this month
    final monthData = List.generate(daysInMonth, (index) {
      final dayTrades = trades.where(
        (t) =>
            t.date.day == (index + 1) &&
            t.date.month == viewMonth.month &&
            t.date.year == viewMonth.year,
      );
      if (dayTrades.isEmpty) return null; // No trades on this day

      return dayTrades.fold(0.0, (sum, t) => sum + t.profitLoss);
    });

    return Column(
      children: [
        // Day name headers (Mon, Tue, etc.)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days
              .map(
                (day) => Text(
                  day,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        // The interactive grid of days
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          // We add the offset of the first weekday to make the calendar look correct
          itemCount: daysInMonth + firstWeekday,
          itemBuilder: (context, index) {
            // Skip cells before the first day of the month
            if (index < firstWeekday) {
              return const SizedBox.shrink();
            }

            final dayIndex = index - firstWeekday;
            final dayNumber = dayIndex + 1;
            final value = monthData[dayIndex];
            
            // Determine if this cell represents the selected date
            final isSelected = selectedDate != null &&
                selectedDate!.day == dayNumber &&
                selectedDate!.month == viewMonth.month &&
                selectedDate!.year == viewMonth.year;

            // Simple check for weekends based on index
            final isWeekend = (index % 7 == 5 || index % 7 == 6);
            
            final cellDate = DateTime(viewMonth.year, viewMonth.month, dayNumber);

            return InkWell(
              onTap: () => onDaySelected(cellDate),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                decoration: BoxDecoration(
                  color: _getHeatmapColor(value, isWeekend),
                  borderRadius: BorderRadius.circular(6),
                  // Highlight selection or today's date
                  border: isSelected
                      ? Border.all(color: AppColors.accent, width: 2)
                      : (dayNumber == DateTime.now().day && 
                         viewMonth.month == DateTime.now().month &&
                         viewMonth.year == DateTime.now().year)
                        ? Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5)
                        : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: value != null || isSelected
                          ? Colors.white
                          : AppColors.textSecondary.withValues(alpha: 0.5),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Calculates color intensity based on profit/loss value
  Color _getHeatmapColor(double? val, bool isWeekend) {
    if (val == null) {
      return isWeekend 
        ? AppColors.surface.withValues(alpha: 0.3) 
        : AppColors.surfaceHighlight.withValues(alpha: 0.3);
    }
    if (val == 0) return AppColors.surfaceHighlight;
    if (val >= 1000) return AppColors.profit;
    if (val > 0) return AppColors.profit.withValues(alpha: 0.6);
    if (val <= -500) return AppColors.loss;
    return AppColors.loss.withValues(alpha: 0.6);
  }
}
