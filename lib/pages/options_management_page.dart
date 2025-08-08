// lib/pages/options_management_page.dart
import 'package:flutter/material.dart';

class OptionsManagementPage extends StatefulWidget {
  final String title;
  final ValueNotifier<List<String>> optionsNotifier;
  final Future<void> Function(List<String>) onUpdate;
  final Future<void> Function() onReset;
  final Future<void> Function(String) onAdd;

  const OptionsManagementPage({
    super.key,
    required this.title,
    required this.optionsNotifier,
    required this.onUpdate,
    required this.onReset,
    required this.onAdd,
  });

  @override
  _OptionsManagementPageState createState() => _OptionsManagementPageState();
}

class _OptionsManagementPageState extends State<OptionsManagementPage> {

  void _addNewOption() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加新选项'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: '输入选项名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await widget.onAdd(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text('添加'),
          ),
        ],
      ),
    );
  }
  
  void _showResetConfirmDialog() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
            title: Text("确认恢复"),
            content: Text("确定要将选项恢复到默认配置吗？您的自定义内容将会丢失。"),
            actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("取消"),
                ),
                TextButton(
                    onPressed: () async {
                        await widget.onReset();
                        Navigator.pop(context);
                    },
                    child: Text("恢复", style: TextStyle(color: Colors.red)),
                ),
            ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.restore_from_trash_outlined),
            tooltip: '恢复默认',
            onPressed: _showResetConfirmDialog,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: widget.optionsNotifier,
        builder: (context, options, child) {
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // 为 FAB 留出空间
            itemCount: options.length,
            itemBuilder: (context, index) {
              final item = options[index];
              return ListTile(
                key: ValueKey(item),
                title: Text(item),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // “其他”项不可删除
                    if (item != '其他')
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        onPressed: () {
                          final currentOptions = List<String>.from(options)..removeAt(index);
                          widget.onUpdate(currentOptions.cast<String>());
                        },
                      ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ],
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              final currentOptions = List.from(options);
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = currentOptions.removeAt(oldIndex);
              currentOptions.insert(newIndex, item);
              widget.onUpdate(currentOptions.cast<String>());
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewOption,
        child: Icon(Icons.add),
      ),
    );
  }
}