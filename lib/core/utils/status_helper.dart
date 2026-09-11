import 'package:flutter/material.dart';

class StatusHelper {
  static String getReadableStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PENDING_MANAGER':
        return 'Pending Manager';
      case 'APPROVED_1':
      case 'PENDING_OWNER':
        return 'Pending Owner';
      case 'APPROVED_2':
      case 'PENDING_CASHIER':
      case 'PENDING_FINANCE':
        return 'Pending Cashier';
      case 'PAID':
      case 'SETTLED':
        return 'Paid & Settled';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PENDING_MANAGER':
        return Colors.orange;
      case 'APPROVED_1':
      case 'PENDING_OWNER':
        return Colors.blue;
      case 'APPROVED_2':
      case 'PENDING_CASHIER':
      case 'PENDING_FINANCE':
        return Colors.purple;
      case 'PAID':
      case 'SETTLED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String getReadableAuditAction(String action) {
    switch (action.toUpperCase()) {
      case 'SUBMITTED': return 'Claim Submitted';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'PAID': return 'Payment Disbursed';
      default: return action;
    }
  }

}
