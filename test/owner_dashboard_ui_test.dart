import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_motors/features/dashboard/presentation/pages/owner_dashboard.dart';
import 'package:dev_motors/features/dashboard/presentation/widgets/add_staff_dialog.dart';

void main() {
  testWidgets('OwnerDashboard renders Add New Staff button and opens AddStaffDialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: OwnerDashboard(),
      ),
    );

    // Pump frame to render UI
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Add New Staff'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.byIcon(Icons.person_add_alt_1), findsWidgets);

    await tester.tap(find.text('Add New Staff'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AddStaffDialog), findsOneWidget);
    expect(find.text('Add Dealership Staff'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Employee ID (e.g. DM002)'), findsOneWidget);
    expect(find.text('Dealership Branch'), findsOneWidget);
    expect(find.text('Temporary Password'), findsOneWidget);
    expect(find.text('Create Staff'), findsOneWidget);
  });
}
