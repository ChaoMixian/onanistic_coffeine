// lib/pages/record_page.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/record.dart';

// Note: 统一管理UI常量
class _UIConstants {
  static const double padding = 16.0;
  static const double spacing = 12.0;
  static const double borderRadius = 16.0;
}

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  // Refactored: 使用 FormKey 进行标准表单验证
  final _formKey = GlobalKey<FormState>();
  
  // Note: 为文本框创建 Controller
  late TextEditingController _customReasonController;
  late TextEditingController _notesController;

  // 表单状态
  DateTime _startTime = DateTime.now();
  int _duration = 0;
  bool _didResist = false;
  int _feeling = 3;
  int _comfort = 3;
  String? _selectedReason; // 使用可空类型，'其他' 也是一个有效选项
  
  // Note: 增加保存状态，防止重复点击
  bool _isSaving = false;

  final List<String> _reasonOptions = [
    '压力', '无聊', '习惯', '情绪低落', '兴奋',
    '孤独', '焦虑', '失眠', '好奇', '其他',
  ];

  @override
  void initState() {
    super.initState();
    _customReasonController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('记录一次', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_UIConstants.padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MotivationalCard(),
              const SizedBox(height: 24),

              // Refactored: 将各个部分拆分为独立的私有Widget
              _StartTimePicker(
                initialTime: _startTime,
                onTimeChanged: (newTime) {
                  setState(() => _startTime = newTime);
                },
              ),
              const SizedBox(height: 24),

              _ResultSelector(
                didResist: _didResist,
                onChanged: (value) {
                  setState(() => _didResist = value);
                },
              ),
              const SizedBox(height: 24),

              // 根据是否忍住，条件渲染UI
              if (!_didResist) ...[
                _DurationSlider(
                  duration: _duration,
                  onChanged: (value) {
                    setState(() => _duration = value);
                  },
                ),
                const SizedBox(height: 24),
              ],
              
              _FeelingRating(
                feeling: _feeling,
                onChanged: (value) {
                  setState(() => _feeling = value);
                },
              ),
              const SizedBox(height: 24),

              if (!_didResist) ...[
                _ComfortRating(
                  comfort: _comfort,
                  onChanged: (value) {
                    setState(() => _comfort = value);
                  },
                ),
                const SizedBox(height: 24),
              ],

              _ReasonSelector(
                options: _reasonOptions,
                selectedReason: _selectedReason,
                customReasonController: _customReasonController,
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
              ),
              const SizedBox(height: 24),

              _NotesField(controller: _notesController),
              const SizedBox(height: 32),

              _SaveButton(
                isSaving: _isSaving,
                onPressed: _saveRecord,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _saveRecord() async {
    // 使用 FormKey 进行验证
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('请填写所有必填项');
      return;
    }
    
    // 手动检查未包含在Form中的选项
    if (_selectedReason == null) {
      _showErrorMessage('请选择主要原因');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final finalReason = _selectedReason == '其他'
          ? _customReasonController.text
          : _selectedReason!;
      
      final record = Record(
        startTime: _startTime,
        duration: _didResist ? 0 : _duration,
        didResist: _didResist,
        feeling: _feeling,
        comfort: _didResist ? 0 : _comfort,
        reason: finalReason,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await DatabaseHelper.instance.insertRecord(record);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('记录已保存！继续加油！'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _resetForm();
      }
    } catch (e) {
      _showErrorMessage('保存失败，请重试');
    } finally {
      if(mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _startTime = DateTime.now();
      _duration = 0;
      _didResist = false;
      _feeling = 3;
      _comfort = 3;
      _selectedReason = null;
      _customReasonController.clear();
      _notesController.clear();
      _formKey.currentState?.reset();
    });
  }
}

// --- Section Title Widget ---
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool required;

  const _SectionTitle(this.title, this.icon, {this.required = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text('*', style: TextStyle(color: theme.colorScheme.error, fontSize: 16)),
        ],
      ],
    );
  }
}


// --- Form Section Widgets ---
class _MotivationalCard extends StatelessWidget {
  const _MotivationalCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_UIConstants.padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.5),
            theme.colorScheme.tertiaryContainer.withOpacity(0.5)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_UIConstants.borderRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite_border, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: _UIConstants.spacing),
          Expanded(
            child: Text(
              '记录是成长的第一步，你已经很棒了！',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartTimePicker extends StatelessWidget {
  final DateTime initialTime;
  final ValueChanged<DateTime> onTimeChanged;

  const _StartTimePicker({required this.initialTime, required this.onTimeChanged});

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialTime),
      );
      
      if (time != null) {
        onTimeChanged(DateTime(
          date.year, date.month, date.day,
          time.hour, time.minute,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('开始时间', Icons.schedule_outlined),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDateTime(context),
          borderRadius: BorderRadius.circular(_UIConstants.borderRadius),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(_UIConstants.borderRadius),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${initialTime.month}月${initialTime.day}日 ${initialTime.hour.toString().padLeft(2, '0')}:${initialTime.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultSelector extends StatelessWidget {
  final bool didResist;
  final ValueChanged<bool> onChanged;

  const _ResultSelector({required this.didResist, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('结果', Icons.psychology_outlined),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _ResultOption(
                title: '成功忍住了',
                subtitle: '你做得很好！',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                isSelected: didResist,
                onTap: () => onChanged(true),
              ),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.2)),
              _ResultOption(
                title: '没有忍住',
                subtitle: '没关系，继续努力',
                icon: Icons.cancel_outlined,
                color: Colors.orange,
                isSelected: !didResist,
                onTap: () => onChanged(false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultOption extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResultOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
        size: 28,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: isSelected ? Icon(Icons.check_circle, color: color, size: 24) : null,
      selected: isSelected,
      selectedTileColor: color.withOpacity(0.05),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final int duration;
  final ValueChanged<int> onChanged;

  const _DurationSlider({required this.duration, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('持续时间', Icons.timer_outlined),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  '$duration 分钟',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: duration.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  onChanged: (value) => onChanged(value.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0分钟', style: theme.textTheme.bodySmall),
                    Text('120分钟', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

abstract class _BaseRating extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final String title;
  final IconData titleIcon;
  final Color color;

  const _BaseRating({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.titleIcon,
    required this.color,
  });
  
  List<String> get labels;
  List<IconData> get icons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title, titleIcon),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final isSelected = value == index + 1;
                    return GestureDetector(
                      onTap: () => onChanged(index + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? color : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          border: Border.all(
                            color: isSelected ? color : theme.dividerColor,
                            width: 2,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: Icon(
                          icons[index],
                          color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  labels[value - 1],
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeelingRating extends _BaseRating {
  const _FeelingRating({required int feeling, required ValueChanged<int> onChanged})
    : super(value: feeling, onChanged: onChanged, title: '感觉如何', titleIcon: Icons.sentiment_satisfied_outlined, color: Colors.blue);

  @override
  List<String> get labels => ['很差', '较差', '一般', '较好', '很好'];
  @override
  List<IconData> get icons => [
    Icons.sentiment_very_dissatisfied, Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral, Icons.sentiment_satisfied, Icons.sentiment_very_satisfied,
  ];
}

class _ComfortRating extends _BaseRating {
  const _ComfortRating({required int comfort, required ValueChanged<int> onChanged})
    : super(value: comfort, onChanged: onChanged, title: '舒适程度', titleIcon: Icons.spa_outlined, color: Colors.green);
    
  @override
  List<String> get labels => ['很不适', '不适', '一般', '舒适', '很舒适'];
  @override
  List<IconData> get icons => [
    Icons.sentiment_very_dissatisfied, Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral, Icons.sentiment_satisfied, Icons.sentiment_very_satisfied,
  ];
}

class _ReasonSelector extends StatelessWidget {
  final List<String> options;
  final String? selectedReason;
  final TextEditingController customReasonController;
  final ValueChanged<String> onChanged;
  
  const _ReasonSelector({
    required this.options,
    required this.selectedReason,
    required this.customReasonController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('主要原因', Icons.psychology_alt_outlined),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(_UIConstants.padding),
            child: Column(
              children: [
                Wrap(
                  spacing: _UIConstants.spacing,
                  runSpacing: _UIConstants.spacing,
                  children: options.map((reason) {
                    return ChoiceChip(
                      label: Text(reason),
                      selected: selectedReason == reason,
                      onSelected: (selected) {
                        if (selected) onChanged(reason);
                      },
                    );
                  }).toList(),
                ),
                if (selectedReason == '其他') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: customReasonController,
                    decoration: const InputDecoration(
                      hintText: '请输入具体原因...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (selectedReason == '其他' && (value == null || value.trim().isEmpty)) {
                        return '选择“其他”时，原因不能为空';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ],
              ],
            ),
          ),
        )
      ],
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});

  @override
  Widget build(BuildContext antext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('备注', Icons.note_add_outlined, required: false),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _UIConstants.padding),
            child: TextFormField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '记录当时的想法、感受或其他细节...',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;

  const _SaveButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon: isSaving 
            ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Icon(Icons.check_circle_outline),
        label: Text(isSaving ? '正在保存...' : '保存记录'),
        onPressed: (isSaving) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}