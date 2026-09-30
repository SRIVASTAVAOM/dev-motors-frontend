import 'package:flutter_test/flutter_test.dart';
import 'package:dev_motors/core/utils/claim_workflow_engine.dart';

void main() {
  group('Department Categorization & Workflow Tests', () {
    test('1. Explicit Sales members resolve to "Sales" category', () {
      final salesUsers = [
        {'id': 'nexa_stephen_sm', 'name': 'Stephen', 'role': 'EMPLOYEE'},
        {'id': 'main_ahmar_gm', 'name': 'Ahmar', 'role': 'MANAGER'},
        {'id': 'khair_pankaj_sm', 'name': 'Pankaj', 'role': 'EMPLOYEE'},
        {'id': 'atrauli_raj_sm', 'name': 'Raj Vardhan', 'role': 'EMPLOYEE'},
        {'id': 'iglas_nitesh_sm', 'name': 'Nitesh Pal', 'role': 'EMPLOYEE'},
        {'id': 'main_shibli_rec', 'name': 'Shibli', 'role': 'EMPLOYEE'},
        {'id': 'iglas_shibli_rec', 'name': 'Shibli', 'role': 'EMPLOYEE'},
      ];

      for (final user in salesUsers) {
        expect(
          ClaimWorkflowEngine.getDepartment(user),
          equals('Sales'),
          reason: '${user['name']} should belong to Sales department',
        );
      }
    });

    test('2. All other users default to "Service" category', () {
      final serviceUsers = [
        {'id': 'nexa_muneesh_bsm', 'name': 'Muneesh Kumar', 'role': 'EMPLOYEE'},
        {'id': 'nexa_deepak_wm', 'name': 'Deepak Sharma', 'role': 'MANAGER'},
        {'id': 'tech_amit_mech', 'name': 'Amit Kumar', 'role': 'EMPLOYEE'},
        {'id': 'unknown_user_1', 'name': 'Random Employee', 'role': 'EMPLOYEE'},
      ];

      for (final user in serviceUsers) {
        expect(
          ClaimWorkflowEngine.getDepartment(user),
          equals('Service'),
          reason: '${user['name']} should belong to Service department',
        );
      }
    });

    test('3. Sales Owners are properly identified', () {
      // Sumit Agrwal & Gaurav Sharma
      expect(ClaimWorkflowEngine.isSalesOwner({'id': 'owner_sumit', 'name': 'Sumit Agrwal'}), isTrue);
      expect(ClaimWorkflowEngine.isSalesOwner({'id': 'owner_gaurav_sharma', 'name': 'Gaurav Sharma'}), isTrue);
      expect(ClaimWorkflowEngine.isSalesOwner({'name': 'Sumit Agarwal'}), isTrue);

      expect(ClaimWorkflowEngine.isServiceOwner({'id': 'owner_sumit', 'name': 'Sumit Agrwal'}), isFalse);
    });

    test('4. Service Owners are properly identified', () {
      // Arpit Verma & Drona Agrwal
      expect(ClaimWorkflowEngine.isServiceOwner({'id': 'owner_arpit', 'name': 'Arpit Verma'}), isTrue);
      expect(ClaimWorkflowEngine.isServiceOwner({'id': 'owner_dron', 'name': 'Drona Agrwal'}), isTrue);
      expect(ClaimWorkflowEngine.isServiceOwner({'name': 'Drona Agarwal'}), isTrue);

      expect(ClaimWorkflowEngine.isSalesOwner({'id': 'owner_arpit', 'name': 'Arpit Verma'}), isFalse);
    });

    test('5. Expense claim department extraction works correctly', () {
      final salesClaim = {
        'id': 'exp_sales_1',
        'employeeName': 'Stephen',
        'location': 'Aligarh Nexa',
        'department': 'Sales',
      };

      final serviceClaim = {
        'id': 'exp_service_1',
        'employeeName': 'Muneesh Kumar',
        'location': 'Aligarh Workshop',
        'department': 'Service',
      };

      expect(ClaimWorkflowEngine.getDepartment(salesClaim), equals('Sales'));
      expect(ClaimWorkflowEngine.getDepartment(serviceClaim), equals('Service'));

      // Check matching filter
      expect(ClaimWorkflowEngine.matchesDepartment(salesClaim, 'All'), isTrue);
      expect(ClaimWorkflowEngine.matchesDepartment(salesClaim, 'Sales'), isTrue);
      expect(ClaimWorkflowEngine.matchesDepartment(salesClaim, 'Service'), isFalse);

      expect(ClaimWorkflowEngine.matchesDepartment(serviceClaim, 'All'), isTrue);
      expect(ClaimWorkflowEngine.matchesDepartment(serviceClaim, 'Sales'), isFalse);
      expect(ClaimWorkflowEngine.matchesDepartment(serviceClaim, 'Service'), isTrue);
    });
  });
}
