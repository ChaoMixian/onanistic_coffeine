// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'dart:math';

import '../db/database_helper.dart';
import '../models/record.dart';
import '../utils/date_utils.dart';
import '../widgets/record_list_item.dart';
import 'widgets/all_records_sheet.dart';
import 'widgets/record_detail_sheet.dart';

// --- Constants ---
class _UIConstants {
  static const double padding = 16.0;
  static const double spacing = 12.0;
  static const double borderRadius = 16.0;
  static const Duration animationDuration = Duration(milliseconds: 800);
}

// --- Data Model for Statistics ---
class HomePageStats {
  // ... (此部分代码与上次优化后相同，此处省略以保持简洁)
  // 月度统计
  final int recordCountThisMonth;
  final int resistCountThisMonth;
  final int averageDuration;
  final double successRate;

  // 周度统计
  final int recordCountThisWeek;
  final int resistCountThisWeek;
  final double weekSuccessRate;

  // 趋势数据
  final List<DayData> weekTrend;
  final Map<String, int> reasonStats;

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
  });

  factory HomePageStats.fromRecords(List<Record> allRecords) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    List<Record> thisMonthRecords = [];
    List<Record> thisWeekRecords = [];
    Map<int, DayData> trendDataMap = {};

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dateKey = day.year * 10000 + day.month * 100 + day.day;
      trendDataMap[dateKey] = DayData(
        date: day,
        recordCount: 0,
        resistCount: 0,
      );
    }

    for (final record in allRecords) {
      if (record.startTime.isAfter(startOfMonth)) {
        thisMonthRecords.add(record);
      }
      if (record.startTime.isAfter(startOfWeekDate)) {
        thisWeekRecords.add(record);
      }
      final recordDateKey =
          record.startTime.year * 10000 +
          record.startTime.month * 100 +
          record.startTime.day;
      if (trendDataMap.containsKey(recordDateKey)) {
        final dayData = trendDataMap[recordDateKey]!;
        trendDataMap[recordDateKey] = DayData(
          date: dayData.date,
          recordCount: dayData.recordCount + 1,
          resistCount: dayData.resistCount + (record.didResist ? 1 : 0),
        );
      }
    }

    final int recordCountThisMonth = thisMonthRecords.length;
    final int resistCountThisMonth = thisMonthRecords
        .where((r) => r.didResist)
        .length;
    final successRate = recordCountThisMonth > 0
        ? resistCountThisMonth / recordCountThisMonth
        : 0.0;
    final successRecords = thisMonthRecords.where((r) => !r.didResist).toList();
    final averageDuration = successRecords.isNotEmpty
        ? successRecords.map((r) => r.duration).reduce((a, b) => a + b) ~/
              successRecords.length
        : 0;

    final int recordCountThisWeek = thisWeekRecords.length;
    final int resistCountThisWeek = thisWeekRecords
        .where((r) => r.didResist)
        .length;
    final weekSuccessRate = recordCountThisWeek > 0
        ? resistCountThisWeek / recordCountThisWeek
        : 0.0;

    final reasonStats = <String, int>{};
    for (var record in thisMonthRecords) {
      // 遍历一个记录中的每一个原因
      for (var reason in record.reasons) {
        reasonStats[reason] = (reasonStats[reason] ?? 0) + 1;
      }
    }
    final sortedReasonStats = Map.fromEntries(
      reasonStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return HomePageStats(
      recordCountThisMonth: recordCountThisMonth,
      resistCountThisMonth: resistCountThisMonth,
      averageDuration: averageDuration,
      successRate: successRate,
      recordCountThisWeek: recordCountThisWeek,
      resistCountThisWeek: resistCountThisWeek,
      weekSuccessRate: weekSuccessRate,
      weekTrend: trendDataMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date)),
      reasonStats: sortedReasonStats,
    );
  }
}

class DayData {
  final DateTime date;
  final int recordCount;
  final int resistCount;
  DayData({
    required this.date,
    required this.recordCount,
    required this.resistCount,
  });
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
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _UIConstants.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final allRecords = await DatabaseHelper.instance.getAllRecords();
    final newStats = HomePageStats.fromRecords(allRecords);

    if (mounted) {
      setState(() {
        _allRecords = allRecords;
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
                  SliverAppBar(
                    expandedHeight: 60,
                    floating: false,
                    pinned: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    elevation: 0,
                    centerTitle: false,
                    title: Text(
                      '手冲咖啡', // 这是一个示例名称
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    titleSpacing: _UIConstants.padding,
                  ),
                  SliverToBoxAdapter(
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
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- build methods for sections ---
  // (这些 build 方法保持不变, 它们现在是 HomePage 的主体框架)
  String _getMotivationalText() {
    if (_stats.recordCountThisMonth == 0) return '开始你的健康之旅';
    final successRate = _stats.successRate * 100;
    if (successRate >= 80) return '表现优异！继续保持！';
    if (successRate >= 60) return '不错的进步，继续努力！';
    if (successRate >= 40) return '一点一滴都是进步';
    return '每一次记录都是成长';
  }

  Widget _buildOverviewSection() {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animation),
        child: Column(
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
          ],
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(_UIConstants.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(_UIConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
    );
  }

  Widget _buildWeekProgressCard() {
    final weekSuccessRate = _stats.weekSuccessRate;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(_UIConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
    );
  }

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
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
                .map(
                  (record) => RecordListItem(
                    record: record,
                    onTap: () => _showRecordDetail(record),
                  ),
                )
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
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有记录',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('点击下方“+”按钮开始记录', style: Theme.of(context).textTheme.bodyMedium),
        ],
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
              '数据分析',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: _UIConstants.padding),
        if (_allRecords.length < 3)
          _buildInsufficientDataCard()
        else ...[
          _buildTrendCard(),
          const SizedBox(height: _UIConstants.padding),
          if (_stats.reasonStats.isNotEmpty) _buildReasonAnalysis(),
        ],
      ],
    );
  }

  Widget _buildInsufficientDataCard() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_UIConstants.borderRadius),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
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
            '至少需要3条记录才能显示趋势分析',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_UIConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
    );
  }

  Widget _buildSimpleChart() {
    if (_stats.weekTrend.isEmpty) return const SizedBox();

    final maxCount = _stats.weekTrend
        .map((d) => d.recordCount)
        .reduce((a, b) => max(a, b));

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
    final topReasons = _stats.reasonStats.entries.take(10).toList();
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_UIConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '主要原因',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...topReasons.map((entry) {
            final percentage = entry.value / _stats.recordCountThisMonth;
            final colors = [
              Colors.red[400]!,
              Colors.orange[400]!,
              Colors.yellow[600]!,
              Colors.green[400]!,
              Colors.blue[400]!,
              Colors.purple[400]!,
              Colors.teal[400]!,
              Colors.pink[400]!,
              Colors.brown[400]!,
              Colors.grey[400]!,
              Colors.indigo[400]!,
              Colors.cyan[400]!,
              Colors.lime[400]!,
              Colors.amber[400]!,
              Colors.deepOrange[400]!,
              Colors.lightGreen[400]!,
              Colors.lightBlue[400]!,
              Colors.deepPurple[400]!,
              Colors.blueGrey[400]!,
              Colors.pinkAccent[400]!,
              Colors.lightBlueAccent[400]!,
              Colors.greenAccent[400]!,
            ];
            final color = colors[topReasons.indexOf(entry) % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- show modal methods ---
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
          Navigator.pop(context); // Close the 'AllRecordsSheet' first
          _showRecordDetail(record);
        },
      ),
    );
  }
}
