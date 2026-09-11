import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

class ExportHelper {
  static void exportExpensesToCsv(List<dynamic> expenses, {String branchName = 'All'}) {
    if (expenses.isEmpty) return;

    final rows = <List<String>>[
      [
        'Claim ID',
        'Date',
        'Employee Name',
        'Employee ID',
        'Branch / Location',
        'Category',
        'Vehicle / Reg No',
        'Description',
        'Amount (INR)',
        'Status',
        'Manager Remarks',
      ]
    ];

    for (var e in expenses) {
      final dateStr = e['createdAt'] != null
          ? DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.parse(e['createdAt']))
          : 'N/A';

      rows.add([
        (e['id'] ?? '').toString(),
        dateStr,
        (e['employee']?['name'] ?? 'N/A').toString(),
        (e['employee']?['employeeId'] ?? 'N/A').toString(),
        (e['location']?['name'] ?? 'Main Dealership').toString(),
        (e['category']?['name'] ?? 'General').toString(),
        (e['vehicleNo'] ?? 'N/A').toString(),
        ('"${(e['description'] ?? '').toString().replaceAll('"', '""')}"'),
        (e['amount'] ?? '0').toString(),
        (e['status'] ?? 'PENDING').toString(),
        ('"${(e['managerRemarks'] ?? e['ownerRemarks'] ?? '').toString().replaceAll('"', '""')}"'),
      ]);
    }

    final csvString = rows.map((r) => r.join(',')).join('\n');
    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'DevMotors_Expense_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
