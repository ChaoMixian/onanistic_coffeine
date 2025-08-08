// lib/pages/widgets/all_records_sheet.dart
import 'package:flutter/material.dart';
import '../../models/record.dart';
import '../../widgets/record_list_item.dart'; // 导入复用的列表项 Widget

class AllRecordsSheet extends StatefulWidget {
  final List<Record> records;
  final Function(Record) onRecordTap; // 回调函数，用于处理点击事件

  const AllRecordsSheet({
    super.key,
    required this.records,
    required this.onRecordTap,
  });

  @override
  _AllRecordsSheetState createState() => _AllRecordsSheetState();
}

class _AllRecordsSheetState extends State<AllRecordsSheet> {
  late List<Record> _filteredRecords;
  String _filterType = 'all'; // all, success, failed

  @override
  void initState() {
    super.initState();
    // 默认显示所有记录，并按时间正序排列
    _filteredRecords = List.from(widget.records);
  }

  void _applyFilter(String filterType) {
    setState(() {
      _filterType = filterType;
      switch (filterType) {
        case 'success':
          _filteredRecords =
              widget.records.where((r) => r.didResist).toList().reversed.toList();
          break;
        case 'failed':
          _filteredRecords =
              widget.records.where((r) => !r.didResist).toList().reversed.toList();
          break;
        default:
          _filteredRecords = List.from(widget.records.reversed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 顶部拖拽条
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 标题和筛选
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '全部记录',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '共 ${widget.records.length} 条',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 筛选按钮
                    Row(
                      children: [
                        _buildFilterChip(context, '全部', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, '成功', 'success'),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, '失败', 'failed'),
                      ],
                    ),
                  ],
                ),
              ),

              // 记录列表
              Expanded(
                child: _filteredRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '没有找到相关记录',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = _filteredRecords[index];
                          // 使用复用的 Widget
                          return RecordListItem(
                            record: record,
                            onTap: () => widget.onRecordTap(record),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final isSelected = _filterType == value;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _applyFilter(value);
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : theme.colorScheme.outline.withOpacity(0.5),
      ),
    );
  }
}