class ExpenseDateHelper {
  static String formatDateTime(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) {
      return 'Today, Just now';
    }
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      
      int hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      
      return '$day $month $year • $hour:$minute $period';
    } catch (_) {
      return dateStr.toString().split('T').first;
    }
  }

  static Map<String, dynamic> getDeadlineInfo(dynamic dateStr, String status) {
    final st = status.toUpperCase();
    if (st == 'PAID' || st == 'APPROVED') {
      return {
        'text': 'Settled & Approved',
        'isOverdue': false,
        'isSettled': true,
      };
    }
    if (st == 'REJECTED') {
      return {
        'text': 'Claim Rejected',
        'isOverdue': false,
        'isSettled': true,
      };
    }

    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final deadline = dt.add(const Duration(hours: 48));
      final now = DateTime.now();
      final diff = deadline.difference(now);

      if (diff.isNegative) {
        return {
          'text': 'Overdue by ${diff.inHours.abs()} hrs (High Priority)',
          'isOverdue': true,
          'isSettled': false,
        };
      } else {
        if (diff.inHours > 0) {
          return {
            'text': 'Deadline: ${diff.inHours} hrs left for approval',
            'isOverdue': false,
            'isSettled': false,
          };
        } else {
          return {
            'text': 'Deadline: ${diff.inMinutes} mins left (Expiring)',
            'isOverdue': true,
            'isSettled': false,
          };
        }
      }
    } catch (_) {
      return {
        'text': 'Deadline: 48 Hours SLA',
        'isOverdue': false,
        'isSettled': false,
      };
    }
  }
}
