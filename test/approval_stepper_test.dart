import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_motors/features/expenses/presentation/widgets/approval_stepper.dart';
import 'package:dev_motors/core/utils/claim_workflow_engine.dart';

void main() {
  group('ApprovalStepper Widget Tests', () {
    testWidgets('renders pending manager state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApprovalStepper(status: 'PENDING_MANAGER'),
          ),
        ),
      );

      expect(find.text('1. Emp'), findsOneWidget);
      expect(find.text('2. Mgr'), findsOneWidget);
      expect(find.text('3. Own'), findsOneWidget);
      expect(find.text('4. Paid'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget); // Step 1 is completed
    });

    testWidgets('renders manager approved / in owner review state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApprovalStepper(status: 'APPROVED'),
          ),
        ),
      );

      expect(find.text('1. Emp'), findsOneWidget);
      expect(find.text('2. Mgr'), findsOneWidget);
      expect(find.text('3. Own'), findsOneWidget);
      expect(find.text('4. Paid'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNWidgets(2)); // Step 1 and Step 2 completed
      expect(find.text('Manager Approved • In Owner Review Queue'), findsOneWidget);
    });

    testWidgets('renders cashier payout ready state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApprovalStepper(status: 'OWNER_APPROVED'),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNWidgets(3)); // Steps 1, 2, 3 completed
      expect(find.text('Owner Approved • Forwarded to Cashier for Payout'), findsOneWidget);
    });

    testWidgets('renders settled / paid state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApprovalStepper(status: 'PAID'),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNWidgets(4)); // All 4 steps completed
      expect(find.text('Settled & Paid • Funds Disbursed'), findsOneWidget);
    });

    testWidgets('renders rejected state with custom reason and red cross', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApprovalStepper(
              status: 'REJECTED',
              rejectionReason: 'Tax invoice missing',
            ),
          ),
        ),
      );

      expect(find.text('1. Emp'), findsOneWidget);
      expect(find.text('2. Mgr ✕'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget); // Red cross on step 2
      expect(find.text('Rejected by Manager: Tax invoice missing'), findsOneWidget);
    });

    testWidgets('renders manager-created claim with 3-step timeline (1. Mgr -> 2. Own -> 3. Paid) and owner review banner', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApprovalStepper(
              status: 'PENDING_MANAGER',
              creatorRole: 'MANAGER',
            ),
          ),
        ),
      );

      expect(find.text('1. Mgr'), findsOneWidget);
      expect(find.text('2. Own'), findsOneWidget);
      expect(find.text('3. Paid'), findsOneWidget);
      expect(find.text('1. Emp'), findsNothing); // Employee has NO role in manager expense!
      expect(find.byIcon(Icons.check), findsOneWidget); // Step 1 (Mgr) completed
      expect(find.text('Manager Claim • In Owner Review Queue'), findsOneWidget);
    });

    testWidgets('renders manager-created claim rejected by owner with red cross on step 2 (Own)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApprovalStepper(
              status: 'REJECTED',
              creatorRole: 'MANAGER',
              rejectionReason: 'Exceeded department budget',
            ),
          ),
        ),
      );

      expect(find.text('1. Mgr'), findsOneWidget);
      expect(find.text('2. Own ✕'), findsOneWidget);
      expect(find.text('3. Paid'), findsOneWidget);
      expect(find.text('1. Emp'), findsNothing); // Employee has NO role in manager expense!
      expect(find.byIcon(Icons.check), findsOneWidget); // Step 1 (Mgr) completed
      expect(find.byIcon(Icons.close), findsOneWidget); // Red cross on step 2 (Owner)
      expect(find.text('Rejected by Owner: Exceeded department budget'), findsOneWidget);
    });
  });

  group('Rejection Remark Caching in ClaimWorkflowEngine', () {
    test('stores and retrieves rejection remark correctly', () {
      ClaimWorkflowEngine.setRejectionRemark('test-exp-123', 'Fuel bill unreadable');
      expect(ClaimWorkflowEngine.getRejectionRemark('test-exp-123'), equals('Fuel bill unreadable'));
    });

    test('falls back to map remarks if not in cache', () {
      final exp = {'remarks': 'Exceeded daily cap'};
      expect(ClaimWorkflowEngine.getRejectionRemark('unknown-id', exp), equals('Exceeded daily cap'));
    });

    test('falls back to default reason if neither cache nor map has reason', () {
      expect(ClaimWorkflowEngine.getRejectionRemark('unknown-id-2', {}), equals('Policy criteria not met'));
    });
  });
}
