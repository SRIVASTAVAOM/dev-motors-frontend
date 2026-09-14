import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_motors/features/dashboard/presentation/pages/owner_dashboard.dart';
import 'package:dev_motors/features/dashboard/presentation/pages/manager_dashboard.dart';
import 'package:dev_motors/features/dashboard/presentation/pages/cashier_dashboard.dart';
import 'package:dev_motors/features/dashboard/presentation/pages/employee_dashboard.dart';

void main() {
  testWidgets('All 4 dashboards have unified executive headers with chips and 3-dot menu', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Owner Dashboard
    await tester.pumpWidget(const MaterialApp(home: OwnerDashboard()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('Managing Director / Owner'), findsOneWidget);
    expect(find.text('All Dealerships Oversight'), findsOneWidget);

    // 2. Manager Dashboard
    await tester.pumpWidget(const MaterialApp(home: ManagerDashboard()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('Branch Manager'), findsAtLeastNWidgets(1));

    // 3. Cashier Dashboard
    await tester.pumpWidget(const MaterialApp(home: CashierDashboard()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('Cashier & Accounts'), findsOneWidget);

    // 4. Employee Dashboard
    await tester.pumpWidget(const MaterialApp(home: EmployeeDashboard()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('Operations Staff'), findsOneWidget);
  });
}
