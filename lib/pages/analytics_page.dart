import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/record.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _selectedPeriod = 0; // 0: 本周, 1: 本月, 2: 本年
  final List<String> _periods = ['本周', '本月', '本年'];

  List<Record> _allRecords = [];
  List<Record> _filteredRecords = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() async {
    final records = await DatabaseHelper.instance.getAllRecords();
    setState(() {
      _allRecords = records;
      _applyFilter();
    });
  }

  void _applyFilter() {
    DateTime now = DateTime.now();
    DateTime start;

    if (_selectedPeriod == 0) {
      // start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    } else if (_selectedPeriod == 1) {
      start = DateTime(now.year, now.month, 1);
    } else {
      start = DateTime(now.year, 1, 1);
    }

    setState(() {
      _filteredRecords = _allRecords.where((r) => r.startTime.isAfter(start)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    int total = _filteredRecords.length;
    int success = _filteredRecords.where((r) => r.didResist).length;
    double successRate = total == 0 ? 0 : success / total;
    int avgDuration = total == 0 ? 0 : (_filteredRecords.map((r) => r.duration).reduce((a, b) => a + b) / total).round();

    Map<String, int> reasonCount = {};
    for (var r in _filteredRecords) {
      reasonCount[r.reason] = (reasonCount[r.reason] ?? 0) + 1;
    }
    var sortedReasons = reasonCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: Text('数据分析'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间段选择
            Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: List.generate(_periods.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(_periods[index]),
                          selected: _selectedPeriod == index,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPeriod = index;
                                _applyFilter();
                              });
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 16),

            // 总体统计
            Text('总体统计', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatsCard('总记录', '$total', Icons.list, Colors.blue)),
                SizedBox(width: 8),
                Expanded(child: _buildStatsCard('成功次数', '$success', Icons.check_circle, Colors.green)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatsCard('成功率', '${(successRate * 100).round()}%', Icons.trending_up, Colors.orange)),
                SizedBox(width: 8),
                Expanded(child: _buildStatsCard('平均时长', '${avgDuration}分钟', Icons.timer, Colors.red)),
              ],
            ),
            SizedBox(height: 16),

            // 趋势图（按天/周）
            Text('趋势分析', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Card(
              child: Container(
                height: 200,
                padding: EdgeInsets.all(16),
                child: _buildSimpleChart(),
              ),
            ),
            SizedBox(height: 16),

            // 原因分析
            Text('原因分析', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: sortedReasons.take(4).map((e) {
                    double ratio = e.value / total;
                    return _buildReasonItem(e.key, ratio, Colors.primaries[sortedReasons.indexOf(e) % Colors.primaries.length]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart() {
    Map<String, int> counts = {};
    for (var r in _filteredRecords) {
      String key = DateFormat('MM/dd').format(r.startTime);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    var entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.map((e) {
        double height = (e.value * 20).toDouble().clamp(10, 100);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 20,
              height: height,
              decoration: BoxDecoration(
                color: Colors.blue[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 4),
            Text(e.key, style: TextStyle(fontSize: 10)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildReasonItem(String reason, double percentage, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(reason)),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          SizedBox(width: 8),
          Text('${(percentage * 100).round()}%'),
        ],
      ),
    );
  }
}
