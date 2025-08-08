// lib/pages/home/streak_and_calendar_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 定义每日状态的枚举
enum DayStatus { failed, resisted, neutral }

class StreakAndCalendarSection extends StatefulWidget {
  final Map<DateTime, DayStatus> dailyStatus;
  final int currentStreak;
  final int longestStreak;

  const StreakAndCalendarSection({
    super.key,
    required this.dailyStatus,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  _StreakAndCalendarSectionState createState() =>
      _StreakAndCalendarSectionState();
}

class _StreakAndCalendarSectionState extends State<StreakAndCalendarSection> {
  late PageController _pageController;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    // PageController初始页面设为足够大，以支持向左滑动
    _pageController = PageController(initialPage: 1200);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      // 使用 Material 3 推荐的表面色
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // 连胜记录展示
          _buildStreakInfo(theme),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          // 月份切换和日历
          _buildCalendar(theme),
        ],
      ),
    );
  }

  Widget _buildStreakInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      // 使用更柔和的背景色
      color: theme.colorScheme.surfaceContainerLowest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _streakCounter('当前连续坚持', widget.currentStreak, theme.colorScheme.primary),
          Container(
            width: 1,
            height: 40,
            color: theme.dividerColor.withOpacity(0.2),
          ),
          _streakCounter('历史最长纪录', widget.longestStreak, theme.colorScheme.tertiary),
        ],
      ),
    );
  }

  Widget _streakCounter(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$label (天)',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
              Text(
                DateFormat('y年 MMMM', 'zh_CN').format(_currentMonth),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ],
          ),
        ),
        _buildWeekdays(theme),
        Container(
          height: 250, // 调整高度以适应新的单元格大小
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentMonth = DateTime(
                    DateTime.now().year, DateTime.now().month + (page - 1200));
              });
            },
            itemBuilder: (context, index) {
              final month = DateTime(
                  DateTime.now().year, DateTime.now().month + (index - 1200));
              return _buildMonthGrid(month);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdays(ThemeData theme) {
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays
            .map((day) => Text(day, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)))
            .toList(),
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekdayOfMonth = DateTime(month.year, month.month, 1).weekday;
    
    final totalSlots = ((daysInMonth + firstWeekdayOfMonth - 1) / 7).ceil() * 7;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekdayOfMonth + 2;
        if (dayNumber <= 0 || dayNumber > daysInMonth) {
          return Container(); // Empty cell
        }

        final date = DateTime(month.year, month.month, dayNumber);
        final status = widget.dailyStatus[DateUtils.dateOnly(date)];
        final isToday = DateUtils.isSameDay(date, DateTime.now());

        return Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
          ),
          child: Center(
            child: _buildDayIcon(status),
          ),
        );
      },
    );
  }
  
  Widget _buildDayIcon(DayStatus? status) {
    switch (status) {
      case DayStatus.failed:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.2),
          ),
          child: Center(child: Icon(Icons.close, color: Colors.red[700], size: 16)),
        );
      case DayStatus.resisted:
         return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.25),
          ),
          child: Center(child: Icon(Icons.check, color: Colors.green[800], size: 16)),
        );
      case DayStatus.neutral:
      default:
        // For successful days with no records, show a subtle dot
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        );
    }
  }
}