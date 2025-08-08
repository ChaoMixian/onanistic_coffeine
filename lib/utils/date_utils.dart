// lib/utils/date_utils.dart

/// 根据日期获取星期几的中文名称
String getWeekdayName(DateTime date) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return weekdays[date.weekday - 1];
}

/// 检查给定日期是否是今天
bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}