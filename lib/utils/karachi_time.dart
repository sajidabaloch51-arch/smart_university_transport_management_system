/// Asia/Karachi is UTC+5 year-round (no DST).
class KarachiTime {
  static const Duration offset = Duration(hours: 5);

  static DateTime now() => DateTime.now().toUtc().add(offset);

  /// Returns `yyyy-MM-dd` in Asia/Karachi.
  static String dateString([DateTime? utcOrLocal]) {
    final k = utcOrLocal == null
        ? now()
        : utcOrLocal.toUtc().add(offset);
    final y = k.year.toString().padLeft(4, '0');
    final m = k.month.toString().padLeft(2, '0');
    final d = k.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Combines a calendar day (Karachi) with a local TimeOfDay-like hour/minute
  /// into a UTC [DateTime] suitable for Firestore Timestamps.
  static DateTime combineToUtc(DateTime calendarDay, int hour, int minute) {
    final k = DateTime.utc(
      calendarDay.year,
      calendarDay.month,
      calendarDay.day,
      hour,
      minute,
    ).subtract(offset);
    return k;
  }

  static String formatTime(DateTime utc) {
    final k = utc.toUtc().add(offset);
    final h = k.hour;
    final m = k.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }

  /// e.g. `27 Oct 2026, 9:45 PM` in Asia/Karachi.
  static String formatDateTime(DateTime utc) {
    final k = utc.toUtc().add(offset);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = k.day;
    final month = months[k.month - 1];
    final year = k.year;
    return '$day $month $year, ${formatTime(utc)}';
  }
}
