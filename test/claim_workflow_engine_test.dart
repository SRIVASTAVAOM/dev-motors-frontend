import 'package:flutter_test/flutter_test.dart';
import 'package:dev_motors/core/utils/claim_workflow_engine.dart';

void main() {
  group('ClaimWorkflowEngine - Branch Normalization & Matching', () {
    test('normalizeBranch strips noise words and symbols', () {
      expect(ClaimWorkflowEngine.normalizeBranch('Delhi'), equals('delhi'));
      expect(ClaimWorkflowEngine.normalizeBranch('Delhi Hub'), equals('delhi'));
      expect(ClaimWorkflowEngine.normalizeBranch('Delhi Branch'), equals('delhi'));
      expect(ClaimWorkflowEngine.normalizeBranch('  delhi  '), equals('delhi'));
      expect(ClaimWorkflowEngine.normalizeBranch('Delhi - Center'), equals('delhi'));
      expect(ClaimWorkflowEngine.normalizeBranch('Delhi Dealership'), equals('delhi'));
      expect(ClaimWorkflowEngine.normalizeBranch('South Delhi Center'), equals('south delhi'));
      expect(ClaimWorkflowEngine.normalizeBranch('Noida Office'), equals('noida'));
      expect(ClaimWorkflowEngine.normalizeBranch({'name': 'Delhi Hub'}), equals('delhi'));
      expect(ClaimWorkflowEngine.normalizeBranch(null), equals(''));
      expect(ClaimWorkflowEngine.normalizeBranch(''), equals(''));
    });

    test('normalizeBranch preserves admin keywords', () {
      expect(ClaimWorkflowEngine.normalizeBranch('all'), equals('all'));
      expect(ClaimWorkflowEngine.normalizeBranch('ALL'), equals('all'));
      expect(ClaimWorkflowEngine.normalizeBranch('hq'), equals('hq'));
      expect(ClaimWorkflowEngine.normalizeBranch('headquarters'), equals('headquarters'));
      expect(ClaimWorkflowEngine.normalizeBranch('admin'), equals('admin'));
    });

    test('matchesBranch enforces strict location isolation between branches', () {
      // Delhi manager matches Delhi claims
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'Delhi', expenseBranch: 'Delhi'),
        isTrue,
      );
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'Delhi Hub', expenseBranch: 'Delhi Branch'),
        isTrue,
      );
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'delhi', expenseBranch: 'Delhi Hub'),
        isTrue,
      );

      // Delhi manager must strictly NOT see Noida or Gurgaon claims
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'Delhi', expenseBranch: 'Noida'),
        isFalse,
      );
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'Delhi Hub', expenseBranch: 'Noida Hub'),
        isFalse,
      );
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'Noida', expenseBranch: 'Delhi'),
        isFalse,
      );
    });

    test('matchesBranch allows admin and global multi-branch visibility', () {
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'all', expenseBranch: 'Delhi'),
        isTrue,
      );
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'HQ', expenseBranch: 'Noida'),
        isTrue,
      );
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'Headquarters', expenseBranch: 'Delhi Hub'),
        isTrue,
      );
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'admin', expenseBranch: 'Mumbai'),
        isTrue,
      );
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: '', expenseBranch: 'Delhi'),
        isTrue,
      );
      expect(
        ClaimWorkflowEngine.matchesBranch(userBranch: 'Delhi', expenseBranch: 'all'),
        isTrue,
      );
    });
  });

  group('ClaimWorkflowEngine - Approval State Machine & Permissions', () {
    test('isPendingForManager returns true only for initial pending review states', () {
      expect(ClaimWorkflowEngine.isPendingForManager('PENDING'), isTrue);
      expect(ClaimWorkflowEngine.isPendingForManager('SUBMITTED'), isTrue);
      expect(ClaimWorkflowEngine.isPendingForManager('LEVEL_1'), isTrue);
      expect(ClaimWorkflowEngine.isPendingForManager('MANAGER_REVIEW'), isTrue);
      expect(ClaimWorkflowEngine.isPendingForManager('PENDING_MANAGER'), isTrue);
      expect(ClaimWorkflowEngine.isPendingForManager('PENDING_APPROVAL'), isTrue);
      expect(ClaimWorkflowEngine.isPendingForManager(''), isTrue);
    });

    test('isPendingForManager returns false for approved, settled, rejected, and later stages', () {
      expect(ClaimWorkflowEngine.isPendingForManager('MANAGER_APPROVED'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForManager('APPROVED_1'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForManager('APPROVED_OWNER'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForManager('PENDING_OWNER'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForManager('PENDING_CASHIER'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForManager('APPROVED'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForManager('REJECTED'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForManager('PAID'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForManager('SETTLED'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForManager('DISBURSED'), isFalse);
    });

    test('employee active vs history tab separation', () {
      // In-Progress claims
      expect(ClaimWorkflowEngine.isVisibleInEmployeeActive('PENDING'), isTrue);
      expect(ClaimWorkflowEngine.isVisibleInEmployeeActive('MANAGER_APPROVED'), isTrue);
      expect(ClaimWorkflowEngine.isVisibleInEmployeeActive('PENDING_OWNER'), isTrue);
      expect(ClaimWorkflowEngine.isVisibleInEmployeeActive('PENDING_CASHIER'), isTrue);
      expect(ClaimWorkflowEngine.isSettledOrRejected('PENDING'), isFalse);
      expect(ClaimWorkflowEngine.isSettledOrRejected('MANAGER_APPROVED'), isFalse);

      // Terminal claims (Rejected or Paid/Settled)
      expect(ClaimWorkflowEngine.isVisibleInEmployeeActive('REJECTED'), isFalse);
      expect(ClaimWorkflowEngine.isSettledOrRejected('REJECTED'), isTrue);

      expect(ClaimWorkflowEngine.isVisibleInEmployeeActive('PAID'), isFalse);
      expect(ClaimWorkflowEngine.isSettledOrRejected('PAID'), isTrue);

      expect(ClaimWorkflowEngine.isVisibleInEmployeeActive('SETTLED'), isFalse);
      expect(ClaimWorkflowEngine.isSettledOrRejected('SETTLED'), isTrue);

      expect(ClaimWorkflowEngine.isVisibleInEmployeeActive('DISBURSED'), isFalse);
      expect(ClaimWorkflowEngine.isSettledOrRejected('DISBURSED'), isTrue);
    });

    test('getStepperIndex progression', () {
      expect(ClaimWorkflowEngine.getStepperIndex('PENDING'), equals(1));
      expect(ClaimWorkflowEngine.getStepperIndex('MANAGER_REVIEW'), equals(1));
      expect(ClaimWorkflowEngine.getStepperIndex('MANAGER_APPROVED'), equals(2));
      expect(ClaimWorkflowEngine.getStepperIndex('PENDING_OWNER'), equals(2));
      expect(ClaimWorkflowEngine.getStepperIndex('PAID'), equals(3));
      expect(ClaimWorkflowEngine.getStepperIndex('SETTLED'), equals(3));
      expect(ClaimWorkflowEngine.getStepperIndex('REJECTED'), equals(-1));
    });
  });

  group('ClaimWorkflowEngine - 4-Tier Escalation & Bypass Matrix', () {
    test('extractCreatorRole correctly infers role from maps and employee IDs', () {
      expect(ClaimWorkflowEngine.extractCreatorRole({'role': 'MANAGER'}), equals('MANAGER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({'creatorRole': 'OWNER'}), equals('OWNER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({'userRole': 'CASHIER'}), equals('CASHIER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({'employee': {'role': 'MANAGER'}}), equals('MANAGER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({'employeeId': 'DEV_OWNER'}), equals('OWNER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({'employeeId': 'OWNER001'}), equals('OWNER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({'employeeId': 'MGR_DELHI_1'}), equals('MANAGER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({'employeeId': 'CSH_MAIN'}), equals('CASHIER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({'employeeId': 'EMP_102'}), equals('EMPLOYEE'));
      expect(ClaimWorkflowEngine.extractCreatorRole(null), equals('EMPLOYEE'));
    });

    test('Manager-created expense bypasses Manager and directly enters Owner queue', () {
      final mgrExpense = {
        'status': 'PENDING',
        'creatorRole': 'MANAGER',
        'employeeId': 'MGR001',
      };

      // Bypasses manager level 1 review
      expect(ClaimWorkflowEngine.isPendingForManager('PENDING', mgrExpense), isFalse);

      // Enters Owner queue directly
      expect(ClaimWorkflowEngine.isPendingForOwner('PENDING', mgrExpense), isTrue);

      // Not yet in Cashier queue
      expect(ClaimWorkflowEngine.isPendingForCashier('PENDING', mgrExpense), isFalse);
    });

    test('Owner-created expense bypasses Manager and Owner, directly enters Cashier queue', () {
      final ownerExpense = {
        'status': 'PENDING',
        'creatorRole': 'OWNER',
        'employeeId': 'DEV_OWNER',
      };

      // Bypasses manager level 1
      expect(ClaimWorkflowEngine.isPendingForManager('PENDING', ownerExpense), isFalse);

      // Bypasses owner level 2
      expect(ClaimWorkflowEngine.isPendingForOwner('PENDING', ownerExpense), isFalse);

      // Directly enters Cashier payout queue
      expect(ClaimWorkflowEngine.isPendingForCashier('PENDING', ownerExpense), isTrue);
    });

    test('Cashier-created expense enters Owner queue for signoff before self-disbursal', () {
      final cashierExpense = {
        'status': 'PENDING',
        'creatorRole': 'CASHIER',
        'employeeId': 'CSH_01',
      };

      // Bypasses manager level 1
      expect(ClaimWorkflowEngine.isPendingForManager('PENDING', cashierExpense), isFalse);

      // Enters Owner queue for signoff
      expect(ClaimWorkflowEngine.isPendingForOwner('PENDING', cashierExpense), isTrue);

      // Cannot disburse yet before Owner signoff
      expect(ClaimWorkflowEngine.isPendingForCashier('PENDING', cashierExpense), isFalse);
    });

    test('Owner approval forwards claim to Cashier queue', () {
      expect(ClaimWorkflowEngine.isPendingForOwner('OWNER_APPROVED'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForOwner('APPROVED_OWNER'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForOwner('APPROVED_2'), isFalse);
      expect(ClaimWorkflowEngine.isPendingForOwner('PENDING_CASHIER'), isFalse);

      expect(ClaimWorkflowEngine.isPendingForCashier('OWNER_APPROVED'), isTrue);
      expect(ClaimWorkflowEngine.isPendingForCashier('APPROVED_OWNER'), isTrue);
      expect(ClaimWorkflowEngine.isPendingForCashier('APPROVED_2'), isTrue);
      expect(ClaimWorkflowEngine.isPendingForCashier('PENDING_CASHIER'), isTrue);
    });

    test('Terminal states (REJECTED, PAID, SETTLED, DISBURSED) exit all queues', () {
      const terminalStatuses = ['REJECTED', 'PAID', 'SETTLED', 'DISBURSED'];
      for (final s in terminalStatuses) {
        expect(ClaimWorkflowEngine.isPendingForManager(s), isFalse);
        expect(ClaimWorkflowEngine.isPendingForOwner(s), isFalse);
        expect(ClaimWorkflowEngine.isPendingForCashier(s), isFalse);
        expect(ClaimWorkflowEngine.isSettledOrRejected(s), isTrue);
        expect(ClaimWorkflowEngine.isVisibleInEmployeeActive(s), isFalse);
      }
    });

    test('isClaimCreatedByUser matches correctly across UUID, employeeId, and email', () {
      final user = {
        'id': 'uuid-manager-123',
        'employeeId': 'nexa_stephen_sm',
        'email': 'stephen@devmotors.com',
        'role': 'MANAGER',
      };

      // Match via root employeeId matching user UUID
      expect(
        ClaimWorkflowEngine.isClaimCreatedByUser({'employeeId': 'uuid-manager-123'}, user),
        isTrue,
      );

      // Match via nested employee object containing employeeId
      expect(
        ClaimWorkflowEngine.isClaimCreatedByUser({
          'employeeId': 'some-other-id',
          'employee': {'employeeId': 'nexa_stephen_sm'},
        }, user),
        isTrue,
      );

      // Match via userId
      expect(
        ClaimWorkflowEngine.isClaimCreatedByUser({'userId': 'uuid-manager-123'}, user),
        isTrue,
      );

      // Match via nested user email
      expect(
        ClaimWorkflowEngine.isClaimCreatedByUser({
          'user': {'email': 'stephen@devmotors.com'},
        }, user),
        isTrue,
      );

      // Non-matching claim
      expect(
        ClaimWorkflowEngine.isClaimCreatedByUser({
          'employeeId': 'other-uuid',
          'employee': {'employeeId': 'other_emp'},
        }, user),
        isFalse,
      );
    });

    test('Manager-created expense with PENDING_MANAGER status strictly bypasses Manager and enters Owner queue', () {
      final mgrExpense = {
        'id': 'exp-mgr-001',
        'status': 'PENDING_MANAGER',
        'creatorRole': 'MANAGER',
        'employeeId': 'nexa_stephen_sm',
      };

      expect(ClaimWorkflowEngine.isPendingForManager('PENDING_MANAGER', mgrExpense), isFalse);
      expect(ClaimWorkflowEngine.isPendingForOwner('PENDING_MANAGER', mgrExpense), isTrue);
      expect(ClaimWorkflowEngine.isPendingForCashier('PENDING_MANAGER', mgrExpense), isFalse);
    });

    test('markOwnerApproved advances claim from Owner queue to Cashier payout queue', () {
      const expId = 'claim-stephen-owner-appr';
      final exp = {
        'id': expId,
        'status': 'PENDING_OWNER',
        'creatorRole': 'MANAGER',
      };

      expect(ClaimWorkflowEngine.isOwnerApproved(expId), isFalse);
      expect(ClaimWorkflowEngine.isPendingForOwner('PENDING_OWNER', exp), isTrue);
      expect(ClaimWorkflowEngine.isPendingForCashier('PENDING_OWNER', exp), isFalse);

      // Owner approves claim
      ClaimWorkflowEngine.markOwnerApproved(expId);

      expect(ClaimWorkflowEngine.isOwnerApproved(expId), isTrue);
      expect(ClaimWorkflowEngine.isPendingForOwner('PENDING_OWNER', exp), isFalse);
      expect(ClaimWorkflowEngine.isPendingForCashier('PENDING_OWNER', exp), isTrue);
    });

    test('extractCreatorRole recognizes suffixes like _sm, _wm, _gm and designation', () {
      expect(ClaimWorkflowEngine.extractCreatorRole({'employeeId': 'nexa_stephen_sm'}), equals('MANAGER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({'employeeId': 'nexa_workshop_wm'}), equals('MANAGER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({'employeeId': 'nexa_delhi_gm'}), equals('MANAGER'));
      expect(ClaimWorkflowEngine.extractCreatorRole({
        'employee': {'designation': 'Branch Sales Manager'},
      }), equals('MANAGER'));
    });

    test('extractCreatorRole recognizes Devendra Sharma and Managing Director as OWNER', () {
      expect(ClaimWorkflowEngine.extractCreatorRole({
        'employeeId': 'OWN001',
        'employee': {
          'name': 'Devendra Sharma (Managing Director)',
          'role': 'EMPLOYEE', // Even if database role field says EMPLOYEE!
        }
      }), equals('OWNER'));

      expect(ClaimWorkflowEngine.extractCreatorRole({
        'employee': {'name': 'Devendra Sharma'},
      }), equals('OWNER'));
    });

    test('isClaimCreatedByUser matches by name between user and claim', () {
      final user = {
        'name': 'Dev Kumar Baghel',
        'employeeId': 'khair_dev_wm',
      };

      expect(ClaimWorkflowEngine.isClaimCreatedByUser({
        'employee': {'name': 'Dev Kumar Baghel'},
      }, user), isTrue);

      expect(ClaimWorkflowEngine.isClaimCreatedByUser({
        'employeeName': 'Dev Kumar Baghel',
      }, user), isTrue);
    });

    test('markCashierPaid immediately moves claim to settled history and clears cashier queue', () {
      const expId = 'cashier-settle-test-101';
      final exp = {'id': expId, 'status': 'APPROVED', 'employeeId': 'emp_test_1'};

      ClaimWorkflowEngine.markOwnerApproved(expId);
      expect(ClaimWorkflowEngine.isPendingForCashier('APPROVED', exp), isTrue);
      expect(ClaimWorkflowEngine.isSettledOrRejected('APPROVED', exp), isFalse);

      // Cashier marks paid
      ClaimWorkflowEngine.markCashierPaid(expId);
      expect(ClaimWorkflowEngine.isCashierPaid(expId), isTrue);
      expect(ClaimWorkflowEngine.isPendingForCashier('APPROVED', exp), isFalse);
      expect(ClaimWorkflowEngine.isSettledOrRejected('APPROVED', exp), isTrue);
      expect(ClaimWorkflowEngine.getStepperIndex('APPROVED', exp), equals(3));
    });
  });
}
