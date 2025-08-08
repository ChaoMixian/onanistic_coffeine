// lib/widgets/record_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../utils/date_utils.dart'; // 导入我们刚刚创建的工具文件

/// 一个可复用的 Widget，用于显示单条记录。
class RecordListItem extends StatelessWidget {
  final Record record;
  final VoidCallback onTap;

  const RecordListItem({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('MM月dd日 HH:mm').format(record.startTime);
    final isRecordToday = isToday(record.startTime);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: record.didResist
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  record.didResist ? Icons.check : Icons.close,
                  color: record.didResist ? Colors.green[600] : Colors.red[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isRecordToday
                              ? '今天 ${DateFormat('HH:mm').format(record.startTime)}'
                              : timeStr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isRecordToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '今天',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.didResist
                          ? '成功忍住 · ${record.reasons.join(', ')}' // 将 List<String> 转换为一个字符串
                          : '持续${record.duration}分钟 · ${record.reasons.join(', ')}', // 同上
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
