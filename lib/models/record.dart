// lib/models/record.dart
import 'dart:convert';

class Record {
  int? id;
  DateTime startTime;
  int duration; // 持续时间（分钟）
  bool didResist; // 是否忍住

  // 新增：事前状态 (1-5, 压力->平静)
  int preEventState; 
  // 修改：事后感觉 (1-5, 很差->很好)
  int postEventFeeling; 
  // 修改：疲劳程度 (1-5, 不疲劳->很疲劳)
  int physicalFatigue; 
  // 新增：事件类型
  String eventType; 
  // 修改：原因，支持多个
  List<String> reasons; 
  String? notes; // 额外备注

  Record({
    this.id,
    required this.startTime,
    required this.duration,
    required this.didResist,
    required this.preEventState,
    required this.postEventFeeling,
    required this.physicalFatigue,
    required this.eventType,
    required this.reasons,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'duration': duration,
      'didResist': didResist ? 1 : 0,
      'preEventState': preEventState,
      'postEventFeeling': postEventFeeling,
      'physicalFatigue': physicalFatigue,
      'eventType': eventType,
      // 将 List<String> 转换为 JSON 字符串以便存储
      'reasons': jsonEncode(reasons), 
      'notes': notes,
    };
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      duration: map['duration'],
      didResist: map['didResist'] == 1,
      preEventState: map['preEventState'] ?? 3, // 兼容旧数据
      postEventFeeling: map['postEventFeeling'] ?? map['feeling'], // 兼容旧数据
      physicalFatigue: map['physicalFatigue'] ?? map['comfort'], // 兼容旧数据
      eventType: map['eventType'] ?? '其他', // 兼容旧数据
      // 从 JSON 字符串转回 List<String>
      reasons: List<String>.from(jsonDecode(map['reasons'] ?? '["${map['reason']}"]')), // 兼容旧数据
      notes: map['notes'],
    );
  }
}