// lib/pages/widgets/record_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/record.dart';

class RecordDetailSheet extends StatelessWidget {
  final Record record;

  const RecordDetailSheet({super.key, required this.record});

  // Helper maps for labels
  static const preEventStateLabels = ['压力很大', '有些焦虑', '内心平静', '比较放松', '非常愉悦'];
  static const postEventFeelingLabels = ['很差', '较差', '一般', '较好', '很好'];
  static const physicalFatigueLabels = ['不疲劳', '有点累', '比较累', '很疲劳', '精疲力尽'];


  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 顶部拖拽条
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // 标题
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 详细信息
                    _buildDetailItem(context, '事前状态', preEventStateLabels[record.preEventState - 1], Icons.accessibility_new),
                    _buildDetailItem(context, '事件类型', record.eventType, Icons.category_outlined),
                    _buildDetailItem(context, '主要原因', record.reasons.join(', '), Icons.psychology_alt),
                    
                    if (!record.didResist) ...[
                      _buildDetailItem(context, '持续时间', '${record.duration} 分钟', Icons.timer_outlined),
                      _buildDetailItem(context, '事后感觉', postEventFeelingLabels[record.postEventFeeling - 1], Icons.sentiment_satisfied_outlined),
                      _buildDetailItem(context, '疲劳程度', physicalFatigueLabels[record.physicalFatigue - 1], Icons.battery_charging_full),
                    ],

                    if (record.notes != null && record.notes!.isNotEmpty)
                      _buildDetailItem(context, '备注', record.notes!, Icons.note_alt_outlined),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: record.didResist
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            record.didResist
                ? Icons.check_circle
                : Icons.cancel,
            color: record.didResist
                ? Colors.green[600]
                : Colors.red[600],
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.didResist ? '成功忍住' : '未能忍住',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('yyyy年MM月dd日 HH:mm')
                    .format(record.startTime),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}