// lib/pages/record_page.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/record.dart';
import '../services/options_service.dart';

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
  final _formKey = GlobalKey<FormState>();
  
  // 新增：为自定义事件类型创建控制器
  late TextEditingController _customEventTypeController;
  late TextEditingController _customReasonController;
  late TextEditingController _notesController;

  // --- 表单状态 ---
  DateTime _startTime = DateTime.now();
  bool _didResist = false;
  int _duration = 0;
  
  int _preEventState = 3;
  int _postEventFeeling = 3;
  int _physicalFatigue = 1;
  String? _eventType;
  
  List<String> _selectedReasons = []; 
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _customEventTypeController = TextEditingController();
    _customReasonController = TextEditingController();
    _notesController = TextEditingController();

    if (OptionsService().eventTypes.value.isNotEmpty) {
        _eventType = OptionsService().eventTypes.value.first;
    }
  }

  @override
  void dispose() {
    _customEventTypeController.dispose();
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

              _StartTimePicker(
                initialTime: _startTime,
                onTimeChanged: (newTime) => setState(() => _startTime = newTime),
              ),
              const SizedBox(height: 24),

              _ResultSelector(
                didResist: _didResist,
                onChanged: (value) => setState(() => _didResist = value),
              ),
              const SizedBox(height: 24),

              _PreEventStateRating(
                state: _preEventState,
                onChanged: (value) => setState(() => _preEventState = value),
              ),
              const SizedBox(height: 24),
              
              ValueListenableBuilder<List<String>>(
                  valueListenable: OptionsService().eventTypes,
                  builder: (context, options, child) {
                      if (_eventType != null && !options.contains(_eventType)) {
                          _eventType = options.isNotEmpty ? options.first : null;
                      }
                      return _EventTypeSelector(
                          options: options,
                          selectedType: _eventType,
                          // 传入新的控制器
                          customEventTypeController: _customEventTypeController,
                          onChanged: (value) {
                              if (value != null) {
                                  setState(() => _eventType = value);
                              }
                          },
                      );
                  },
              ),
              const SizedBox(height: 24),

              ValueListenableBuilder<List<String>>(
                  valueListenable: OptionsService().reasons,
                  builder: (context, options, child) {
                      return _ReasonSelector(
                          options: options,
                          selectedReasons: _selectedReasons,
                          customReasonController: _customReasonController,
                          onChanged: (reasons) => setState(() => _selectedReasons = reasons),
                      );
                },
              ),
              const SizedBox(height: 24),

              if (!_didResist) ...[
                _DurationSlider(
                  duration: _duration,
                  onChanged: (value) => setState(() => _duration = value),
                ),
                const SizedBox(height: 24),
                _PostEventFeelingRating(
                  feeling: _postEventFeeling,
                  onChanged: (value) => setState(() => _postEventFeeling = value),
                ),
                const SizedBox(height: 24),
                _PhysicalFatigueRating(
                  fatigue: _physicalFatigue,
                  onChanged: (value) => setState(() => _physicalFatigue = value),
                ),
                const SizedBox(height: 24),
              ],
              
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
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('请填写所有必填项');
      return;
    }
    
    if (_selectedReasons.isEmpty) {
      _showErrorMessage('请至少选择一个主要原因');
      return;
    }
    
    if (_eventType == null) {
      _showErrorMessage('请选择事件类型');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 处理自定义原因
      List<String> finalReasons = List.from(_selectedReasons);
      if (_selectedReasons.contains('其他')) {
        final customReason = _customReasonController.text.trim();
        if (customReason.isNotEmpty) {
          await OptionsService().addReason(customReason);
          finalReasons.remove('其他');
          finalReasons.add(customReason);
        }
      }
      
      // 新增：处理自定义事件类型
      String finalEventType = _eventType!;
      if (_eventType == '其他') {
        final customEventType = _customEventTypeController.text.trim();
        if (customEventType.isNotEmpty) {
          await OptionsService().addEventType(customEventType);
          finalEventType = customEventType;
        }
      }
      
      final record = Record(
        startTime: _startTime,
        didResist: _didResist,
        preEventState: _preEventState,
        eventType: finalEventType,
        reasons: finalReasons,
        duration: _didResist ? 0 : _duration,
        postEventFeeling: _didResist ? 3 : _postEventFeeling,
        physicalFatigue: _didResist ? 1 : _physicalFatigue,
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
      _showErrorMessage('保存失败，请重试: $e');
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
            Expanded(child: Text(message)),
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
      _preEventState = 3;
      _postEventFeeling = 3;
      _physicalFatigue = 1;
      _eventType = OptionsService().eventTypes.value.isNotEmpty ? OptionsService().eventTypes.value.first : null;
      _selectedReasons.clear();
      // 重置所有控制器
      _customEventTypeController.clear();
      _customReasonController.clear();
      _notesController.clear();
      _formKey.currentState?.reset();
    });
  }
}

// --- Section Title Widget (无变化) ---
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool required;

  const _SectionTitle(this.title, this.icon, {this.subtitle, this.required = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        if(subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ]
      ],
    );
  }
}

// --- _EventTypeSelector Widget (已修改) ---
class _EventTypeSelector extends StatelessWidget {
  final List<String> options;
  final String? selectedType;
  final ValueChanged<String?> onChanged;
  // 新增控制器参数
  final TextEditingController customEventTypeController;

  const _EventTypeSelector({
    required this.options,
    required this.selectedType,
    required this.onChanged,
    required this.customEventTypeController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('事件类型', Icons.category_outlined, subtitle: '这次事件发生在哪种常见场景下？'),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(_UIConstants.padding),
            child: Column(
              children: [
                if (options.isEmpty)
                  const Center(child: Text("请在设置中添加事件类型"))
                else
                  Wrap(
                    spacing: _UIConstants.spacing,
                    runSpacing: _UIConstants.spacing,
                    children: options.map((type) {
                      return ChoiceChip(
                        label: Text(type),
                        selected: selectedType == type,
                        onSelected: (selected) {
                          if (selected) onChanged(type);
                        },
                      );
                    }).toList(),
                  ),
                // 新增：当选中“其他”时显示输入框
                if (selectedType == '其他') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: customEventTypeController,
                    decoration: const InputDecoration(
                      hintText: '请输入具体类型并保存，它将成为新选项',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (selectedType == '其他' && (value == null || value.trim().isEmpty)) {
                        return '选择“其他”时，类型不能为空';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// --- 其他 Widgets (无变化) ---

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
        const _SectionTitle('结果', Icons.psychology_outlined, subtitle: "这次是否成功地克制住了冲动？"),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _ResultOption(
                title: '成功忍住了',
                subtitle: '做得很好！为你的自制力点赞。',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                isSelected: didResist,
                onTap: () => onChanged(true),
              ),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.2)),
              _ResultOption(
                title: '没有忍住',
                subtitle: '没关系，记录下来，更好地了解自己。',
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

abstract class _BaseRating extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final String title;
  final String? subtitle;
  final IconData titleIcon;
  final Color color;

  const _BaseRating({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
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
        _SectionTitle(title, titleIcon, subtitle: subtitle),
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

class _PreEventStateRating extends _BaseRating {
  const _PreEventStateRating({required int state, required ValueChanged<int> onChanged})
    : super(
        value: state, 
        onChanged: onChanged, 
        title: '事前状态', 
        subtitle: '在冲动来临时，你的心理状态是怎样的？',
        titleIcon: Icons.accessibility_new, 
        color: Colors.purple
      );

  @override
  List<String> get labels => ['压力很大', '有些焦虑', '内心平静', '比较放松', '非常愉悦'];
  @override
  List<IconData> get icons => [
    Icons.cloud_queue, Icons.sync_problem,
    Icons.waves, Icons.wb_sunny_outlined, Icons.wb_sunny,
  ];
}

class _ReasonSelector extends StatelessWidget {
  final List<String> options;
  final List<String> selectedReasons;
  final TextEditingController customReasonController;
  final ValueChanged<List<String>> onChanged;

  const _ReasonSelector({
    required this.options,
    required this.selectedReasons,
    required this.customReasonController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('主要原因 (可多选)', Icons.psychology_alt_outlined, subtitle: '是什么导致了这次冲动？'),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(_UIConstants.padding),
            child: Column(
              children: [
                if (options.isEmpty)
                  const Center(child: Text("请在设置中添加原因选项"))
                else
                  Wrap(
                    spacing: _UIConstants.spacing,
                    runSpacing: _UIConstants.spacing,
                    children: options.map((reason) {
                      return FilterChip(
                        label: Text(reason),
                        selected: selectedReasons.contains(reason),
                        onSelected: (selected) {
                          final newReasons = List<String>.from(selectedReasons);
                          if (selected) {
                            newReasons.add(reason);
                          } else {
                            newReasons.remove(reason);
                          }
                          onChanged(newReasons);
                        },
                      );
                    }).toList(),
                  ),
                if (selectedReasons.contains('其他')) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: customReasonController,
                    decoration: const InputDecoration(
                      hintText: '请输入具体原因并保存，它将成为新选项',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (selectedReasons.contains('其他') && (value == null || value.trim().isEmpty)) {
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
        ),
      ],
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
        const _SectionTitle('持续时间', Icons.timer_outlined, subtitle: '这次行为持续了多长时间？'),
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

class _PostEventFeelingRating extends _BaseRating {
  const _PostEventFeelingRating({required int feeling, required ValueChanged<int> onChanged})
    : super(
        value: feeling, 
        onChanged: onChanged, 
        title: '事后感觉', 
        subtitle: '结束后，你的心理感觉如何？',
        titleIcon: Icons.sentiment_satisfied_outlined, 
        color: Colors.blue
      );

  @override
  List<String> get labels => ['很差', '较差', '一般', '较好', '很好'];
  @override
  List<IconData> get icons => [
    Icons.sentiment_very_dissatisfied, Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral, Icons.sentiment_satisfied, Icons.sentiment_very_satisfied,
  ];
}

class _PhysicalFatigueRating extends _BaseRating {
  const _PhysicalFatigueRating({required int fatigue, required ValueChanged<int> onChanged})
    : super(
        value: fatigue, 
        onChanged: onChanged, 
        title: '疲劳程度', 
        subtitle: '结束后，你的身体感觉有多疲劳？',
        titleIcon: Icons.battery_charging_full,
        color: Colors.red
      );
    
  @override
  List<String> get labels => ['不疲劳', '有点累', '比较累', '很疲劳', '精疲力尽'];
  @override
  List<IconData> get icons => [
    Icons.battery_full, Icons.battery_6_bar,
    Icons.battery_4_bar, Icons.battery_2_bar, Icons.battery_0_bar,
  ];
}


class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('备注', Icons.note_add_outlined, subtitle: '可以记录当时的想法、感受或其他细节。', required: false),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _UIConstants.padding),
            child: TextFormField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '记录任何你想补充的内容...',
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