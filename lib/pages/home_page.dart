// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'dart:math';

import '../db/database_helper.dart';
import '../models/record.dart';
import '../utils/date_utils.dart';
import '../widgets/record_list_item.dart';
import 'widgets/all_records_sheet.dart';
import 'widgets/record_detail_sheet.dart';

import 'home/streak_and_calendar_section.dart';
import 'home/advanced_analytics_section.dart';

// --- Constants ---
class _UIConstants {
  static const double padding = 16.0;
  static const double spacing = 12.0;
  static const double borderRadius = 16.0;
  static const Duration animationDuration = Duration(milliseconds: 800);
}

// --- Data Model for Statistics (Combined Version) ---
class HomePageStats {
  // Old Stats
  final int recordCountThisMonth;
  final int resistCountThisMonth;
  final int averageDuration;
  final double successRate;
  final int recordCountThisWeek;
  final int resistCountThisWeek;
  final double weekSuccessRate;
  final List<DayData> weekTrend;
  final Map<String, int> reasonStats;

  // New Stats
  final int currentStreak;
  final int longestStreak;
  final Map<DateTime, DayStatus> dailyStatus;
  final List<CorrelationDataPoint> correlationData;
  final Map<int, int> timeOfDayData;
  final List<SuccessRateDataPoint> successRateData;

  HomePageStats({
    required this.recordCountThisMonth,
    required this.resistCountThisMonth,
    required this.averageDuration,
    required this.successRate,
    required this.recordCountThisWeek,
    required this.resistCountThisWeek,
    required this.weekSuccessRate,
    required this.weekTrend,
    required this.reasonStats,
    required this.currentStreak,
    required this.longestStreak,
    required this.dailyStatus,
    required this.correlationData,
    required this.timeOfDayData,
    required this.successRateData,
  });

  factory HomePageStats.fromRecords(List<Record> allRecordsDesc, List<Record> allRecordsAsc) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);

    // --- 1. Calculate Old Stats ---
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeekDate = DateUtils.dateOnly(now.subtract(Duration(days: now.weekday - 1)));

    final thisMonthRecords = allRecordsDesc.where((r) => r.startTime.isAfter(startOfMonth)).toList();
    final thisWeekRecords = allRecordsDesc.where((r) => r.startTime.isAfter(startOfWeekDate)).toList();

    final recordCountThisMonth = thisMonthRecords.length;
    final resistCountThisMonth = thisMonthRecords.where((r) => r.didResist).length;
    final successRate = recordCountThisMonth > 0 ? resistCountThisMonth / recordCountThisMonth : 0.0;
    final failedRecords = thisMonthRecords.where((r) => !r.didResist).toList();
    final averageDuration = failedRecords.isNotEmpty ? failedRecords.map((r) => r.duration).reduce((a, b) => a + b) ~/ failedRecords.length : 0;

    final recordCountThisWeek = thisWeekRecords.length;
    final resistCountThisWeek = thisWeekRecords.where((r) => r.didResist).length;
    final weekSuccessRate = recordCountThisWeek > 0 ? resistCountThisWeek / recordCountThisWeek : 0.0;

    final reasonStats = <String, int>{};
    for (var record in thisMonthRecords) {
      for (var reason in record.reasons) {
        reasonStats[reason] = (reasonStats[reason] ?? 0) + 1;
      }
    }
    final sortedReasonStats = Map.fromEntries(reasonStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));

    final weekTrendDataMap = <DateTime, DayData>{};
    for (int i = 0; i < 7; i++) {
        final day = DateUtils.dateOnly(now.subtract(Duration(days: i)));
        weekTrendDataMap[day] = DayData(date: day, recordCount: 0, resistCount: 0);
    }
    for (final record in thisWeekRecords) {
        final day = DateUtils.dateOnly(record.startTime);
        if (weekTrendDataMap.containsKey(day)) {
            final oldData = weekTrendDataMap[day]!;
            weekTrendDataMap[day] = DayData(
                date: day,
                recordCount: oldData.recordCount + 1,
                resistCount: oldData.resistCount + (record.didResist ? 1 : 0),
            );
        }
    }
    final weekTrend = weekTrendDataMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));


    // --- 2. Calculate New Stats (Streaks, Calendar, Advanced Charts) ---
    final Map<DateTime, DayStatus> dailyStatus = {};
    if (allRecordsAsc.isNotEmpty) {
      final recordsByDay = <DateTime, List<Record>>{};
      for (var record in allRecordsAsc) {
        final day = DateUtils.dateOnly(record.startTime);
        recordsByDay.putIfAbsent(day, () => []).add(record);
      }
      recordsByDay.forEach((day, records) {
        if (records.any((r) => !r.didResist)) {
          dailyStatus[day] = DayStatus.failed;
        } else {
          dailyStatus[day] = DayStatus.resisted;
        }
      });
    }

    int currentStreak = 0;
    int longestStreak = 0;
    if (allRecordsAsc.isNotEmpty) {
      final firstRecordDay = DateUtils.dateOnly(allRecordsAsc.first.startTime);
      int tempStreak = 0;
      for (var i = 0; i <= today.difference(firstRecordDay).inDays; i++) {
        final day = firstRecordDay.add(Duration(days: i));
        if (dailyStatus[day] == DayStatus.failed) {
          if (tempStreak > longestStreak) longestStreak = tempStreak;
          tempStreak = 0;
        } else {
          tempStreak++;
        }
      }
      if (tempStreak > longestStreak) longestStreak = tempStreak;
      
      tempStreak = 0;
      for (var i = 0; ; i++) {
        final day = today.subtract(Duration(days: i));
        if (day.isBefore(firstRecordDay)) {
            if(dailyStatus[firstRecordDay] != DayStatus.failed) {
               tempStreak = today.difference(firstRecordDay).inDays + 1;
            }
            break;
        }
        if (dailyStatus[day] == DayStatus.failed) break;
        tempStreak++;
      }
      currentStreak = tempStreak;
    }

    final correlationData = allRecordsDesc.where((r) => !r.didResist).map((r) => CorrelationDataPoint(r.preEventState, r.postEventFeeling)).toList();
    final timeOfDayData = <int, int>{};
    for (var record in allRecordsDesc) {
      timeOfDayData.update(record.startTime.hour, (value) => value + 1, ifAbsent: () => 1);
    }
    final successRateData = <SuccessRateDataPoint>[];
    if (allRecordsAsc.isNotEmpty) {
        final weeklyRates = <DateTime, List<bool>>{};
        for (var record in allRecordsAsc) {
            final startOfWeek = record.startTime.subtract(Duration(days: record.startTime.weekday - 1));
            final weekKey = DateUtils.dateOnly(startOfWeek);
            weeklyRates.putIfAbsent(weekKey, () => []).add(record.didResist);
        }
        weeklyRates.forEach((week, results) {
            final rate = results.where((r) => r).length / results.length;
            successRateData.add(SuccessRateDataPoint(week, rate));
        });
        successRateData.sort((a,b) => a.date.compareTo(b.date));
    }

    return HomePageStats(
      recordCountThisMonth: recordCountThisMonth,
      resistCountThisMonth: resistCountThisMonth,
      averageDuration: averageDuration,
      successRate: successRate,
      recordCountThisWeek: recordCountThisWeek,
      resistCountThisWeek: resistCountThisWeek,
      weekSuccessRate: weekSuccessRate,
      weekTrend: weekTrend,
      reasonStats: sortedReasonStats,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      dailyStatus: dailyStatus,
      correlationData: correlationData,
      timeOfDayData: timeOfDayData,
      successRateData: successRateData,
    );
  }
}

class DayData {
  final DateTime date;
  final int recordCount;
  final int resistCount;
  DayData({required this.date, required this.recordCount, required this.resistCount});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Record> _allRecords = [];
  late HomePageStats _stats;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _UIConstants.animationDuration,
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    
    final allRecordsDesc = await DatabaseHelper.instance.getAllRecords();
    final allRecordsAsc = await DatabaseHelper.instance.getAllRecordsAsc();
    
    final newStats = HomePageStats.fromRecords(allRecordsDesc, allRecordsAsc);

    if (mounted) {
      setState(() {
        _allRecords = allRecordsDesc;
        _stats = newStats;
        _isLoading = false;
      });
    }

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)),
                        child: Padding(
                          padding: const EdgeInsets.all(_UIConstants.padding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOverviewSection(),
                              const SizedBox(height: 24),
                              _buildRecentRecordsSection(),
                              const SizedBox(height: 24),
                              _buildAnalyticsSection(),
                              const SizedBox(height: 24),
                              AdvancedAnalyticsSection(
                                correlationData: _stats.correlationData,
                                timeOfDayData: _stats.timeOfDayData,
                                successRateData: _stats.successRateData,
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ),
    );
  }
  
  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 60,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      title: Text(
        '手冲咖啡', 
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      titleSpacing: _UIConstants.padding,
    );
  }

  // --- Sections ---

  String _getMotivationalText() {
    if (_stats.recordCountThisMonth == 0) return '开始你的健康之旅';
    final successRate = _stats.successRate * 100;
    if (successRate >= 80) return '表现优异！继续保持！';
    if (successRate >= 60) return '不错的进步，继续努力！';
    if (successRate >= 40) return '一点一滴都是进步';
    return '每一次记录都是成长';
  }

  Widget _buildOverviewSection() {
    return Column(
      children: [
        _buildMotivationalCard(),
        const SizedBox(height: _UIConstants.padding),
        Row(
          children: [
            Expanded(
              child: _buildMainStatCard(
                '本月记录',
                _stats.recordCountThisMonth.toString(),
                Icons.event_note,
                Theme.of(context).colorScheme.primary,
                '次',
              ),
            ),
            const SizedBox(width: _UIConstants.spacing),
            Expanded(
              child: _buildMainStatCard(
                '成功忍住',
                _stats.resistCountThisMonth.toString(),
                Icons.check_circle_outline,
                Colors.green.shade600,
                '次',
              ),
            ),
          ],
        ),
        const SizedBox(height: _UIConstants.spacing),
        Row(
          children: [
            Expanded(
              child: _buildMainStatCard(
                '成功率',
                '${(_stats.successRate * 100).round()}',
                Icons.trending_up,
                Colors.purple.shade500,
                '%',
              ),
            ),
            const SizedBox(width: _UIConstants.spacing),
            Expanded(
              child: _buildMainStatCard(
                '平均时长',
                _stats.averageDuration.toString(),
                Icons.timer_outlined,
                Colors.orange.shade600,
                '分钟',
              ),
            ),
          ],
        ),
        const SizedBox(height: _UIConstants.padding),
        _buildWeekProgressCard(),
        const SizedBox(height: _UIConstants.padding),
        StreakAndCalendarSection(
          dailyStatus: _stats.dailyStatus,
          currentStreak: _stats.currentStreak,
          longestStreak: _stats.longestStreak,
        ),
      ],
    );
  }

  Widget _buildMotivationalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_UIConstants.padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(_UIConstants.borderRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.self_improvement,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: _UIConstants.spacing),
          Expanded(
            child: Text(
              _getMotivationalText(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String unit,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_UIConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(unit, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: _UIConstants.spacing),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekProgressCard() {
    final weekSuccessRate = _stats.weekSuccessRate;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '本周进度',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${_stats.resistCountThisWeek} / ${_stats.recordCountThisWeek}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: weekSuccessRate,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  weekSuccessRate >= 0.8
                      ? Colors.green.shade400
                      : weekSuccessRate >= 0.5
                      ? Colors.orange.shade400
                      : Colors.red.shade400,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '成功率 ${(weekSuccessRate * 100).round()}%',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: textTheme.bodyLarge?.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '基础分析',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: _UIConstants.padding),
        if (_allRecords.length < 3)
          _buildInsufficientDataCard("基础分析")
        else ...[
          _buildTrendCard(),
          const SizedBox(height: _UIConstants.padding),
          if (_stats.reasonStats.isNotEmpty) _buildReasonAnalysis(),
        ],
      ],
    );
  }

  Widget _buildInsufficientDataCard(String title) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              '数据不足',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '至少需要3条记录才能显示$title',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7天趋势',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 120, child: _buildSimpleChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart() {
    if (_stats.weekTrend.isEmpty) return const SizedBox();

    final maxCount = _stats.weekTrend.map((d) => d.recordCount).fold(0, (prev, e) => max(prev, e));

    if (maxCount == 0) {
      return Center(
        child: Text('本周暂无数据', style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _stats.weekTrend.map((dayData) {
        final height = (dayData.recordCount / maxCount * 80.0).clamp(4.0, 80.0);
        final isDayToday = isToday(dayData.date);
        final colorScheme = Theme.of(context).colorScheme;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (dayData.resistCount > 0)
              Container(
                width: 20,
                height: 8,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else
              const SizedBox(height: 10),
            Container(
              width: 20,
              height: height,
              decoration: BoxDecoration(
                color: isDayToday
                    ? colorScheme.primary
                    : colorScheme.primary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              getWeekdayName(dayData.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDayToday
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isDayToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildReasonAnalysis() {
    final topReasons = _stats.reasonStats.entries.take(5).toList();
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '主要原因 (本月)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...topReasons.map((entry) {
              final total = _stats.reasonStats.values.fold(0, (prev, e) => prev + e);
              final percentage = total > 0 ? entry.value / total : 0.0;
              final colors = [
                Colors.red[400]!, Colors.orange[400]!, Colors.yellow[600]!,
                Colors.green[400]!, Colors.blue[400]!,
              ];
              final color = colors[topReasons.indexOf(entry) % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(percentage * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // --- Widget Sections (Recent Records, etc.) ---
  Widget _buildRecentRecordsSection() {
    final recentRecords = _allRecords.take(5).toList();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: textTheme.bodyLarge?.color, size: 20),
            const SizedBox(width: 8),
            Text(
              '最近记录',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _showAllRecords(),
              child: const Text('查看全部'),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: _UIConstants.spacing),
        if (recentRecords.isEmpty)
          _buildEmptyState()
        else
          Column(
            children: recentRecords
                .map((record) => RecordListItem(
                      record: record,
                      onTap: () => _showRecordDetail(record),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(_UIConstants.borderRadius),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            '还没有记录',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text('点击下方“+”按钮开始记录', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  // --- Modal Methods ---
  void _showRecordDetail(Record record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordDetailSheet(record: record),
    );
  }

  void _showAllRecords() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AllRecordsSheet(
        records: _allRecords,
        onRecordTap: (record) {
          Navigator.pop(context); 
          _showRecordDetail(record);
        },
      ),
    );
  }
}