class Record {
  int? id;
  DateTime startTime;
  int duration; // 持续时间（分钟）
  bool didResist; // 是否忍住
  int feeling; // 感觉如何 (1-5)
  int comfort; // 舒适程度 (1-5)
  String reason; // 原因
  String? notes; // 额外备注

  Record({
    this.id,
    required this.startTime,
    required this.duration,
    required this.didResist,
    required this.feeling,
    required this.comfort,
    required this.reason,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'duration': duration,
      'didResist': didResist ? 1 : 0,
      'feeling': feeling,
      'comfort': comfort,
      'reason': reason,
      'notes': notes,
    };
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      duration: map['duration'],
      didResist: map['didResist'] == 1,
      feeling: map['feeling'],
      comfort: map['comfort'],
      reason: map['reason'],
      notes: map['notes'],
    );
  }
}
