// lib/pages/home/advanced_analytics_section.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

// 定义图表所需的数据模型
class CorrelationDataPoint {
  final int preEventState;
  final int postEventFeeling;
  CorrelationDataPoint(this.preEventState, this.postEventFeeling);
}

class SuccessRateDataPoint {
  final DateTime date;
  final double rate;
  SuccessRateDataPoint(this.date, this.rate);
}

class AdvancedAnalyticsSection extends StatelessWidget {
  final List<CorrelationDataPoint> correlationData;
  final Map<int, int> timeOfDayData;
  final List<SuccessRateDataPoint> successRateData;

  const AdvancedAnalyticsSection({
    super.key,
    required this.correlationData,
    required this.timeOfDayData,
    required this.successRateData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, "高级数据洞察", Icons.insights),
        const SizedBox(height: 12),
        _buildCorrelationChart(context),
        const SizedBox(height: 16),
        _buildTimeOfDayChart(context),
        const SizedBox(height: 16),
        _buildSuccessRateChart(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: textTheme.bodyLarge?.color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // --- Chart Widgets ---

  Widget _buildChartCard({required BuildContext context, required String title, required String subtitle, required Widget chartContent, required bool hasData}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            hasData
              ? chartContent
              : _insufficientDataView(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCorrelationChart(BuildContext context) {
    return _buildChartCard(
      context: context,
      title: "事前状态 vs 事后感觉",
      subtitle: "观察情绪如何影响结果",
      hasData: correlationData.length >= 5,
      chartContent: AspectRatio(
        aspectRatio: 1.5,
        child: CustomPaint(
          painter: _ScatterPlotPainter(
            data: correlationData,
            theme: Theme.of(context),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimeOfDayChart(BuildContext context) {
    return _buildChartCard(
      context: context,
      title: "高发时段分析",
      subtitle: "识别一天中的“危险”时刻",
      hasData: timeOfDayData.isNotEmpty,
      chartContent: Container(
        height: 120,
        child: CustomPaint(
          painter: _BarChartPainter(
            data: timeOfDayData,
            theme: Theme.of(context),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
  
  Widget _buildSuccessRateChart(BuildContext context) {
    return _buildChartCard(
      context: context,
      title: "成功率趋势",
      subtitle: "回顾你的长期进步曲线",
      hasData: successRateData.length >= 2,
      chartContent: AspectRatio(
        aspectRatio: 2,
        child: CustomPaint(
          painter: _LineChartPainter(
            data: successRateData,
            theme: Theme.of(context),
          ),
        ),
      ),
    );
  }

  Widget _insufficientDataView(BuildContext context) {
    return Container(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.data_exploration_outlined, size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              '数据不足，无法生成图表',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Painters for Charts ---

class _ScatterPlotPainter extends CustomPainter {
  final List<CorrelationDataPoint> data;
  final ThemeData theme;
  final EdgeInsets padding = const EdgeInsets.only(left: 30, bottom: 20, right: 10, top: 10);

  _ScatterPlotPainter({required this.data, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = theme.dividerColor.withOpacity(0.5)
      ..strokeWidth = 0.5;

    final axisLabelStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    
    final chartWidth = size.width - padding.horizontal;
    final chartHeight = size.height - padding.vertical;

    // Draw grid and labels
    for (int i = 0; i <= 4; i++) {
      final x = padding.left + i * chartWidth / 4;
      final y = padding.top + i * chartHeight / 4;
      
      // Vertical lines
      canvas.drawLine(Offset(x, padding.top), Offset(x, padding.top + chartHeight), gridPaint);
      // Horizontal lines
      canvas.drawLine(Offset(padding.left, y), Offset(padding.left + chartWidth, y), gridPaint);
    }
    
    // Draw axis labels
    _drawAxisLabel(canvas, '压力大', Offset(padding.left - 6, chartHeight + padding.top + 16), axisLabelStyle);
    _drawAxisLabel(canvas, '愉悦', Offset(size.width - padding.right - 6, chartHeight + padding.top + 16), axisLabelStyle, align: TextAlign.left);
    _drawAxisLabel(canvas, '很好', Offset(padding.left - 32, padding.top + 10), axisLabelStyle, align: TextAlign.left, verticalAlign: -1);
    _drawAxisLabel(canvas, '很差', Offset(padding.left - 32, size.height - padding.bottom - 8), axisLabelStyle, align: TextAlign.left, verticalAlign: 1);


    // Draw data points
    final pointPaint = Paint()..color = theme.colorScheme.primary.withOpacity(0.7);
    for (var p in data) {
      final dx = padding.left + (p.preEventState - 1) * chartWidth / 4;
      final dy = padding.top + chartHeight - ((p.postEventFeeling - 1) * chartHeight / 4);
      canvas.drawCircle(Offset(dx, dy), 5, pointPaint);
    }
  }

  void _drawAxisLabel(Canvas canvas, String text, Offset offset, TextStyle? style, {TextAlign align = TextAlign.left, int verticalAlign = 0}) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr, textAlign: align);
    textPainter.layout(minWidth: 0, maxWidth: 50);
    
    double yOffset = offset.dy;
    if (verticalAlign == -1) { // Align top
      yOffset -= textPainter.height;
    } else if (verticalAlign == 0) { // Align center
      yOffset -= textPainter.height / 2;
    }
    // verticalAlign == 1 is align bottom (default)

    textPainter.paint(canvas, Offset(offset.dx, yOffset));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartPainter extends CustomPainter {
  final Map<int, int> data;
  final ThemeData theme;
  final EdgeInsets padding = const EdgeInsets.only(bottom: 20, top: 10);

  _BarChartPainter({required this.data, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final maxCount = data.values.reduce(max);
    final chartHeight = size.height - padding.vertical;
    final barWidth = size.width / 24;
    final paint = Paint()..color = theme.colorScheme.secondary;
    final axisLabelStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    for (int hour = 0; hour < 24; hour++) {
      final count = data[hour] ?? 0;
      final barHeight = maxCount > 0 ? (count / maxCount * chartHeight) : 0.0;
      final left = hour * barWidth;
      final top = padding.top + chartHeight - barHeight;
      final rect = Rect.fromLTWH(left, top, barWidth - 4, barHeight);
      canvas.drawRRect(RRect.fromRectAndCorners(rect, topRight: Radius.circular(4), topLeft: Radius.circular(4)), paint);

      // Draw hour labels at intervals
      if (hour % 6 == 0) {
        final textSpan = TextSpan(text: '$hour', style: axisLabelStyle);
        final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(canvas, Offset(left - (textPainter.width / 2) + (barWidth / 2), size.height - padding.bottom + 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LineChartPainter extends CustomPainter {
  final List<SuccessRateDataPoint> data;
  final ThemeData theme;
  final EdgeInsets padding = const EdgeInsets.only(left: 30, bottom: 20, right: 10, top: 10);

  _LineChartPainter({required this.data, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final chartWidth = size.width - padding.horizontal;
    final chartHeight = size.height - padding.vertical;
    final axisLabelStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    // Draw Y-axis labels
    _drawAxisLabel(canvas, '100%', Offset(padding.left - 8, padding.top), axisLabelStyle, align: TextAlign.right, verticalAlign: 0);
    _drawAxisLabel(canvas, '50%', Offset(padding.left - 8, padding.top + chartHeight / 2), axisLabelStyle, align: TextAlign.right, verticalAlign: 0);
    _drawAxisLabel(canvas, '0%', Offset(padding.left - 8, padding.top + chartHeight), axisLabelStyle, align: TextAlign.right, verticalAlign: 0);

    final linePaint = Paint()
      ..color = theme.colorScheme.tertiary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.colorScheme.tertiary.withOpacity(0.3),
          theme.colorScheme.tertiary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final xStep = chartWidth / (data.length - 1);
    
    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final x = padding.left + xStep * i;
      final y = padding.top + chartHeight - (data[i].rate * chartHeight);
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height - padding.bottom);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i+1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }
    
    fillPath.lineTo(points.last.dx, size.height - padding.bottom);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (var p in points) {
      canvas.drawCircle(p, 4, Paint()..color = theme.colorScheme.tertiary);
    }
    
    // Draw X-axis labels
    if (data.isNotEmpty) {
      _drawAxisLabel(canvas, DateFormat('MM/dd').format(data.first.date), points.first, axisLabelStyle, align: TextAlign.center);
      if (data.length > 1) {
        _drawAxisLabel(canvas, DateFormat('MM/dd').format(data.last.date), points.last, axisLabelStyle, align: TextAlign.center);
      }
    }
  }
  
  void _drawAxisLabel(Canvas canvas, String text, Offset offset, TextStyle? style, {TextAlign align = TextAlign.left, int verticalAlign = 1}) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr, textAlign: align);
    textPainter.layout(minWidth: 0, maxWidth: 50);
    
    double xOffset = offset.dx;
    if (align == TextAlign.center) {
      xOffset -= textPainter.width / 2;
    } else if (align == TextAlign.right) {
      xOffset -= textPainter.width;
    }
    
    double yOffset = offset.dy;
    if (verticalAlign == -1) { // Align top
      yOffset -= textPainter.height;
    } else if (verticalAlign == 0) { // Align center
      yOffset -= textPainter.height / 2;
    } else { // Align bottom
      yOffset += 5; // Add some padding
    }

    textPainter.paint(canvas, Offset(xOffset, yOffset));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
