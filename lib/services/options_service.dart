// lib/services/options_service.dart
import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';

class OptionsService {
  static final OptionsService _instance = OptionsService._internal();
  factory OptionsService() => _instance;
  OptionsService._internal();

  final dbHelper = DatabaseHelper.instance;

  // ValueNotifiers 用于实时更新UI
  final ValueNotifier<List<String>> eventTypes = ValueNotifier([]);
  final ValueNotifier<List<String>> reasons = ValueNotifier([]);

  // 初始化
  Future<void> init() async {
    eventTypes.value = await dbHelper.getOptions('event_types');
    reasons.value = await dbHelper.getOptions('reasons');
  }

  // --- 事件类型管理 ---
  Future<void> updateEventTypes(List<String> newTypes) async {
    await dbHelper.updateOptions('event_types', newTypes);
    eventTypes.value = newTypes; // 更新缓存并通知监听者
  }
  Future<void> addEventType(String type) async {
    await dbHelper.addOption('event_types', type);
    eventTypes.value = await dbHelper.getOptions('event_types');
  }
  Future<void> resetEventTypes() async {
    await dbHelper.resetDefaultOptions('event_types');
    eventTypes.value = await dbHelper.getOptions('event_types');
  }

  // --- 原因管理 ---
  Future<void> updateReasons(List<String> newReasons) async {
    await dbHelper.updateOptions('reasons', newReasons);
    reasons.value = newReasons;
  }
  Future<void> addReason(String reason) async {
    await dbHelper.addOption('reasons', reason);
    reasons.value = await dbHelper.getOptions('reasons');
  }
  Future<void> resetReasons() async {
    await dbHelper.resetDefaultOptions('reasons');
    reasons.value = await dbHelper.getOptions('reasons');
  }
}