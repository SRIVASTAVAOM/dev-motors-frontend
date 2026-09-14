import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_motors/features/dashboard/presentation/pages/owner_dashboard.dart';
import 'package:dev_motors/features/dashboard/presentation/widgets/add_staff_dialog.dart';

void main() {
  testWidgets('OwnerDashboard renders sleek more_vert menu and opens AddStaffDialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: OwnerDashboard(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    // Verify clean header with 3-dot menu
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    // Tap 3-dot menu
    await tester.tap(find.byIcon(Icons.more_vert));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Verify clean popup options
    expect(find.text('Add New Staff'), findsOneWidget);
    expect(find.text('Export Ledger (CSV)'), findsOneWidget);

    // Tap Add New Staff
    await tester.tap(find.text('Add New Staff'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(AddStaffDialog), findsOneWidget);
    expect(find.text('Add Dealership Staff'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Employee ID (e.g. DM002)'), findsOneWidget);
    expect(find.text('Dealership Branch'), findsOneWidget);
    expect(find.text('Temporary Password'), findsOneWidget);
    expect(find.text('Create Staff'), findsOneWidget);
  });
}
