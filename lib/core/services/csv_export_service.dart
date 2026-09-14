import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../utils/safe_parser.dart';
import '../utils/claim_workflow_engine.dart';

class CsvExportService {
  static Future<bool> exportExpensesToCsv(
    List<dynamic> expenses, {
    String filenamePrefix = 'dev_motors_expenses',
    String? branch,
  }) async {
    try {
      final buffer = StringBuffer();

      // CSV Header formatted for Tally Prime / Excel ledger import
      buffer.writeln(
        '"Date","Claim ID","Employee Name","Employee ID","Role","Branch","Category","Purpose","Amount (INR)","Status"',
      );

      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      for (final rawExp in expenses) {
        if (rawExp is! Map) continue;
        final exp = Map<String, dynamic>.from(rawExp);

        // Date
        final rawDate = exp['createdAt'] ?? exp['expenseDate'];
        String formattedDate = '';
        if (rawDate != null) {
          try {
            formattedDate = dateFormat.format(DateTime.parse(rawDate.toString()));
          } catch (_) {
            formattedDate = rawDate.toString();
          }
        }

        final id = SafeParser.getString(exp['id'] ?? exp['_id']);
        final empName = SafeParser.getString(
          exp['employee'] is Map ? exp['employee']['name'] : (exp['employeeName'] ?? exp['userName']),
          'Staff',
        );
        final empId = SafeParser.getString(
          exp['employee'] is Map ? exp['employee']['employeeId'] : exp['employeeId'],
        );
        final role = ClaimWorkflowEngine.extractCreatorRole(exp);
        final expBranch = SafeParser.getString(
          exp['location'] is Map ? exp['location']['name'] : (exp['location'] ?? exp['branch']),
          branch ?? 'Main Dealership',
        );
        final cat = SafeParser.getString(
          exp['category'] is Map ? exp['category']['name'] : exp['category'],
          'General',
        );
        final desc = SafeParser.getString(exp['description'], 'Expense Claim');
        final amt = SafeParser.getDouble(exp['amount']).toStringAsFixed(2);
        final status = SafeParser.getString(exp['status'], 'PENDING');

        buffer.writeln(
          '${_escape(formattedDate)},'
          '${_escape(id)},'
          '${_escape(empName)},'
          '${_escape(empId)},'
          '${_escape(role)},'
          '${_escape(expBranch)},'
          '${_escape(cat)},'
          '${_escape(desc)},'
          '$amt,'
          '${_escape(status)}',
        );
      }

      final csvString = buffer.toString();
      final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final finalFileName = '${filenamePrefix}_$nowStr.csv';

      if (kIsWeb) {
        final bytes = utf8.encode(csvString);
        final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', finalFileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return true;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static String _escape(String field) {
    final sanitized = field.replaceAll('"', '""');
    return '"$sanitized"';
  }
}
