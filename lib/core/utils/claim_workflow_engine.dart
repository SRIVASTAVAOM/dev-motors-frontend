import 'safe_parser.dart';

class ClaimWorkflowEngine {
  static const Set<String> _adminBranchKeywords = {
    'all',
    'hq',
    'headquarters',
    'admin',
    'global',
    'corporate',
    'superuser',
  };

  /// Safely parses string, removes noise like 'branch', 'hub', 'center', symbols,
  /// lowercases and trims.
  static String normalizeBranch(dynamic branch) {
    final raw = SafeParser.getString(branch).trim().toLowerCase();
    if (raw.isEmpty) return '';

    // If it's an administrative keyword, return directly
    if (_adminBranchKeywords.contains(raw)) {
      return raw;
    }

    // Replace non-alphanumeric characters with spaces
    String cleaned = raw.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    // Remove common organizational noise words
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(branch|hub|center|centre|dealership|outlet|office|location|dept|department)\b'),
      ' ',
    );

    // Normalize multiple spaces into single space and trim
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // If noise removal resulted in an empty string, fallback to original cleaned raw string
    if (cleaned.isEmpty) {
      cleaned = raw.replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
    }

    return cleaned.isNotEmpty ? cleaned : raw;
  }

  /// Returns `true` if branches match or if user has administrative global access.
  static bool matchesBranch({
    required dynamic userBranch,
    required dynamic expenseBranch,
    dynamic currentUser,
  }) {
    if (currentUser != null && isSeniorCashier(currentUser)) {
      return true;
    }

    final uNorm = normalizeBranch(userBranch);
    final eNorm = normalizeBranch(expenseBranch);

    // Administrative / Senior Cashier / Superuser access check
    if (uNorm.isEmpty ||
        _adminBranchKeywords.contains(uNorm) ||
        uNorm.contains('chief') ||
        uNorm.contains('finance') ||
        uNorm.contains('senior') ||
        uNorm.contains('head') ||
        uNorm.contains('central')) {
      return true;
    }

    if (eNorm.isEmpty || _adminBranchKeywords.contains(eNorm)) {
      return true;
    }

    if (uNorm == eNorm) {
      return true;
    }

    if (uNorm.contains(eNorm) || eNorm.contains(uNorm)) {
      return true;
    }

    return false;
  }

  /// Safely determines if the user has Senior / Chief Cashier privileges with company-wide oversight.
  static bool isSeniorCashier(dynamic user) {
    if (user == null) return false;
    final empId = SafeParser.getString(user is Map ? user['employeeId'] : user).toUpperCase().trim();
    final name = SafeParser.getString(user is Map ? user['name'] : '').toLowerCase();
    final desig = SafeParser.getString(user is Map ? (user['designation'] ?? user['title']) : '').toLowerCase();
    final branch = SafeParser.getString(user is Map ? (user['branch'] ?? (user['location'] is Map ? user['location']['name'] : user['location'])) : '').toLowerCase();
    return empId == 'CASH001' ||
        name.contains('chief') ||
        name.contains('senior') ||
        name.contains('finance') ||
        desig.contains('chief') ||
        desig.contains('senior') ||
        desig.contains('finance') ||
        branch.contains('chief') ||
        branch.contains('central');
  }

  /// Safely determines whether a claim was created by the given user.
  static bool isClaimCreatedByUser(dynamic exp, Map<String, dynamic>? user) {
    if (exp is! Map || user == null) return false;

    final myId = SafeParser.getString(user['id'] ?? user['_id']).toLowerCase().trim();
    final myEmpId = SafeParser.getString(user['employeeId']).toLowerCase().trim();
    final myEmail = SafeParser.getString(user['email']).toLowerCase().trim();
    final myName = SafeParser.getString(user['name'] ?? user['userName'] ?? user['fullName']).toLowerCase().trim();
    final myPhone = SafeParser.getString(user['phone']).toLowerCase().trim();

    final expEmpId = SafeParser.getString(exp['employeeId']).toLowerCase().trim();
    final expUserId = SafeParser.getString(exp['userId'] ?? exp['createdById']).toLowerCase().trim();

    dynamic nestedEmp = exp['employee'];
    String nestedEmpId = '';
    String nestedId = '';
    String nestedEmail = '';
    String nestedName = '';
    String nestedPhone = '';
    if (nestedEmp is Map) {
      nestedEmpId = SafeParser.getString(nestedEmp['employeeId']).toLowerCase().trim();
      nestedId = SafeParser.getString(nestedEmp['id'] ?? nestedEmp['_id']).toLowerCase().trim();
      nestedEmail = SafeParser.getString(nestedEmp['email']).toLowerCase().trim();
      nestedName = SafeParser.getString(nestedEmp['name'] ?? nestedEmp['userName']).toLowerCase().trim();
      nestedPhone = SafeParser.getString(nestedEmp['phone']).toLowerCase().trim();
    }

    dynamic nestedUser = exp['user'] ?? exp['createdBy'];
    if (nestedUser is Map) {
      if (nestedId.isEmpty) nestedId = SafeParser.getString(nestedUser['id'] ?? nestedUser['_id']).toLowerCase().trim();
      if (nestedEmail.isEmpty) nestedEmail = SafeParser.getString(nestedUser['email']).toLowerCase().trim();
      if (nestedName.isEmpty) nestedName = SafeParser.getString(nestedUser['name']).toLowerCase().trim();
    }

    final topName = SafeParser.getString(
      exp['employeeName'] ?? exp['userName'] ?? (exp['employee'] is String ? exp['employee'] : ''),
    ).toLowerCase().trim();

    // 1. Match by UUID or raw DB ID
    if (myId.isNotEmpty) {
      if (expEmpId == myId || expUserId == myId || nestedId == myId) return true;
    }
    // 2. Match by human-readable employeeId
    if (myEmpId.isNotEmpty) {
      if (expEmpId == myEmpId || nestedEmpId == myEmpId) return true;
    }
    // 3. Match by email
    if (myEmail.isNotEmpty) {
      if (nestedEmail == myEmail) return true;
    }
    // 4. Match by Name (exact or clean contains)
    if (myName.isNotEmpty) {
      for (final expN in [nestedName, topName]) {
        if (expN.isNotEmpty) {
          if (expN == myName || expN.contains(myName) || myName.contains(expN)) return true;
        }
      }
    }
    // 5. Match by Phone
    if (myPhone.isNotEmpty && nestedPhone.isNotEmpty && myPhone == nestedPhone) {
      return true;
    }

    return false;
  }

  /// Safely determines the creator's role ('EMPLOYEE', 'MANAGER', 'OWNER', 'CASHIER').
  static String extractCreatorRole(dynamic exp) {
    if (exp == null) return 'EMPLOYEE';
    if (exp is! Map) return 'EMPLOYEE';

    final empObj = exp['employee'];

    // 1. Check Name & Designation keywords FIRST
    final empName = SafeParser.getString(
      empObj is Map ? empObj['name'] : (exp['employeeName'] ?? exp['userName'] ?? (exp['employee'] is String ? exp['employee'] : '')),
    ).toUpperCase().trim();

    final empDesig = SafeParser.getString(
      empObj is Map ? empObj['designation'] : (exp['designation'] ?? exp['employeeDesignation']),
    ).toUpperCase().trim();

    if (empName.contains('MANAGING DIRECTOR') ||
        empName.contains('EXECUTIVE DIRECTOR') ||
        empName.contains('DIRECTOR') ||
        empName.contains('DEVENDRA SHARMA') ||
        empName.contains('SUMIT AGARWAL') ||
        empName.contains('DRONA AGARWAL') ||
        empName.contains('OWNER') ||
        empDesig.contains('MANAGING DIRECTOR') ||
        empDesig.contains('EXECUTIVE DIRECTOR') ||
        empDesig.contains('DIRECTOR') ||
        empDesig.contains('PARTNER') ||
        empDesig.contains('OWNER')) {
      return 'OWNER';
    }

    if (empDesig.contains('CASHIER') ||
        empDesig.contains('ACCOUNTANT') ||
        empName.contains('CASHIER') ||
        empName.contains('ACCOUNTANT')) {
      return 'CASHIER';
    }

    // Bodyshop Manager in directory is explicitly EMPLOYEE reporting to Showroom Manager
    if (empDesig.contains('BODYSHOP') || empName.contains('RAJENDRA') || empDesig.contains('BSM') || empDesig.contains('CCM')) {
      return 'EMPLOYEE';
    }

    if (empDesig.contains('MANAGER') ||
        empDesig.contains('MGR') ||
        empDesig.contains('SHOWROOM MGR') ||
        empDesig.contains('WORKSHOP MGR')) {
      return 'MANAGER';
    }

    // 2. Infer from Employee ID prefix or suffix
    final empId = SafeParser.getString(
      exp['employeeId'] ?? (empObj is Map ? empObj['employeeId'] : empObj) ?? exp['userId'],
    ).toUpperCase().trim();

    final nestedEmpId = empObj is Map ? SafeParser.getString(empObj['employeeId']).toUpperCase().trim() : '';

    for (final id in [empId, nestedEmpId]) {
      if (id.isEmpty) continue;
      if (id.startsWith('OWN') || id.startsWith('DEV_OWN') || id.startsWith('ADM') || id.contains('_OWN') || id.contains('OWNER_')) {
        return 'OWNER';
      }
      if (id.startsWith('MGR') ||
          id.startsWith('DEV_MGR') ||
          id.contains('_MGR') ||
          id.endsWith('_SM') ||
          id.endsWith('_WM') ||
          id.endsWith('_GM') ||
          id.contains('_SM_') ||
          id.contains('_WM_') ||
          id.contains('_GM_') ||
          id.contains('KHAIR_DEV')) {
        return 'MANAGER';
      }
      if (id.startsWith('CSH') ||
          id.startsWith('DEV_CSH') ||
          id.startsWith('ACC') ||
          id.contains('_CSH') ||
          id.contains('_ACC') ||
          id.endsWith('_ACC') ||
          id.contains('_CASHIER')) {
        return 'CASHIER';
      }
    }

    // 3. Check explicit role fields
    final directRole = SafeParser.getString(
      exp['creatorRole'] ?? exp['employeeRole'] ?? exp['userRole'] ?? exp['role'],
    ).toUpperCase().trim();
    if (directRole.isNotEmpty) {
      if (directRole.contains('OWNER') || directRole.contains('ADMIN')) return 'OWNER';
      if (directRole.contains('MANAGER') || directRole.contains('MGR')) return 'MANAGER';
      if (directRole.contains('CASHIER') || directRole.contains('ACCOUNTANT')) return 'CASHIER';
    }

    if (empObj is Map) {
      final nestedRole = SafeParser.getString(empObj['role']).toUpperCase().trim();
      if (nestedRole.isNotEmpty) {
        if (nestedRole.contains('OWNER') || nestedRole.contains('ADMIN')) return 'OWNER';
        if (nestedRole.contains('MANAGER') || nestedRole.contains('MGR')) return 'MANAGER';
        if (nestedRole.contains('CASHIER') || nestedRole.contains('ACCOUNTANT')) return 'CASHIER';
      }
    }

    return 'EMPLOYEE';
  }

  static final Set<String> _ownerApprovedExpenseIds = {};
  static final Set<String> _cashierPaidExpenseIds = {};

  /// Records that a claim has been approved by the Owner, moving it to Cashier queue.
  static void markOwnerApproved(String expenseId) {
    if (expenseId.isNotEmpty) {
      _ownerApprovedExpenseIds.add(expenseId);
    }
  }

  /// Checks if an expense has been approved by the Owner.
  static bool isOwnerApproved(String expenseId) {
    return _ownerApprovedExpenseIds.contains(expenseId);
  }

  /// Records that a claim has been disbursed/paid by the Cashier, moving it to settled History.
  static void markCashierPaid(String expenseId) {
    if (expenseId.isNotEmpty) {
      _cashierPaidExpenseIds.add(expenseId);
      _ownerApprovedExpenseIds.remove(expenseId);
    }
  }

  /// Checks if an expense has been marked as paid/settled by the Cashier.
  static bool isCashierPaid(String expenseId) {
    return _cashierPaidExpenseIds.contains(expenseId);
  }

  /// Returns `true` only for initial pending states (`PENDING`, `SUBMITTED`, `LEVEL_1`, `MANAGER_REVIEW`, `PENDING_MANAGER`).
  /// Returns `false` for `PENDING_OWNER`, `PENDING_CASHIER`, `APPROVED`, `REJECTED`, `PAID`, etc.
  static bool isPendingForManager(dynamic rawStatus, [dynamic exp]) {
    if (isSettledOrRejected(rawStatus, exp)) return false;

    // Check bypass FIRST: Manager, Owner, or Cashier-created claims NEVER enter Manager level 1 review
    if (exp != null) {
      final role = extractCreatorRole(exp);
      if (role == 'MANAGER' || role == 'OWNER' || role == 'CASHIER') {
        return false;
      }
    }

    final id = exp is Map ? SafeParser.getString(exp['id'] ?? exp['_id']) : '';
    if (id.isNotEmpty && isOwnerApproved(id)) {
      return false;
    }

    final s = SafeParser.getString(rawStatus).toUpperCase().trim();
    if (s.isEmpty) return true;

    // Explicit checks for later stages
    if (s == 'PENDING_OWNER' ||
        s == 'PENDING_CASHIER' ||
        s.contains('OWNER') ||
        s.contains('CASHIER') ||
        s.contains('FINANCE') ||
        s.contains('DIRECTOR') ||
        s == 'APPROVED' ||
        s == 'APPROVED_1' ||
        s == 'APPROVED_2' ||
        s == 'MANAGER_APPROVED' ||
        s == 'APPROVED_OWNER' ||
        s == 'OWNER_APPROVED') {
      return false;
    }

    // Initial pending stages
    return s == 'PENDING' ||
        s == 'SUBMITTED' ||
        s == 'LEVEL_1' ||
        s == 'MANAGER_REVIEW' ||
        s == 'PENDING_APPROVAL' ||
        s == 'PENDING_MANAGER' ||
        (s.contains('PENDING') && !s.contains('OWNER') && !s.contains('CASHIER'));
  }

  /// Returns `true` if claim is in Owner review queue.
  /// Incorporates the bypass matrix: Manager-created and Cashier-created expenses
  /// directly enter the Owner queue.
  static bool isPendingForOwner(dynamic rawStatus, [dynamic exp]) {
    if (isSettledOrRejected(rawStatus, exp)) return false;

    final id = exp is Map ? SafeParser.getString(exp['id'] ?? exp['_id']) : '';
    if (id.isNotEmpty && isOwnerApproved(id)) {
      return false; // Owner has already signed off
    }

    final s = SafeParser.getString(rawStatus).toUpperCase().trim();

    // If forwarded to Cashier or already approved by Owner
    if (s == 'PENDING_CASHIER' ||
        s == 'APPROVED_2' ||
        s == 'OWNER_APPROVED' ||
        s == 'APPROVED_OWNER' ||
        s == 'APPROVED' ||
        s.contains('CASHIER')) {
      return false;
    }

    // Standard Owner review states
    if (s == 'PENDING_OWNER' ||
        s == 'APPROVED_1' ||
        s == 'MANAGER_APPROVED' ||
        s.contains('DIRECTOR') ||
        s == 'LEVEL_2') {
      return true;
    }

    // Escalation & Bypass Matrix:
    // - Manager Creates Expense -> Directly enters Owner Queue.
    // - Cashier Creates Expense -> Enters Owner Queue for signoff before self-disbursal.
    if (exp != null) {
      final role = extractCreatorRole(exp);
      if (role == 'MANAGER' || role == 'CASHIER') {
        return true;
      }
    }

    return false;
  }

  /// Returns `true` if claim is in Cashier payout queue.
  /// Incorporates the bypass matrix: Owner-created expenses directly enter Cashier Queue.
  static bool isPendingForCashier(dynamic rawStatus, [dynamic exp]) {
    final id = exp is Map ? SafeParser.getString(exp['id'] ?? exp['_id']) : (exp is String ? exp : '');
    if (id.isNotEmpty && isCashierPaid(id)) {
      return false; // Cashier has already disbursed / settled this claim
    }

    if (isSettledOrRejected(rawStatus, exp)) return false;

    if (id.isNotEmpty && isOwnerApproved(id)) {
      return true; // Moved to Cashier upon Owner approval
    }

    final s = SafeParser.getString(rawStatus).toUpperCase().trim();

    // Standard Cashier payout states:
    // PENDING_CASHIER, APPROVED_2, OWNER_APPROVED, APPROVED_OWNER, APPROVED
    if (s == 'PENDING_CASHIER' ||
        s == 'APPROVED_2' ||
        s == 'OWNER_APPROVED' ||
        s == 'APPROVED_OWNER' ||
        s == 'APPROVED' ||
        s.contains('CASHIER')) {
      return true;
    }

    // Escalation & Bypass Matrix:
    // - Owner Creates Expense -> Directly enters Cashier Queue.
    if (exp != null &&
        (s == 'PENDING' || s == 'SUBMITTED' || s == 'PENDING_APPROVAL' || s == 'PENDING_MANAGER' || s.isEmpty)) {
      final role = extractCreatorRole(exp);
      if (role == 'OWNER') {
        return true;
      }
    }

    return false;
  }

  /// Returns `true` if claim is in progress; returns `false` if `REJECTED`, `PAID`, `SETTLED`, or `DISBURSED`.
  static bool isVisibleInEmployeeActive(dynamic rawStatus, [dynamic exp]) {
    return !isSettledOrRejected(rawStatus, exp);
  }

  /// Returns `true` for `REJECTED`, `PAID`, `SETTLED`, `DISBURSED`, or marked paid by Cashier.
  static bool isSettledOrRejected(dynamic rawStatus, [dynamic exp]) {
    final id = exp is Map ? SafeParser.getString(exp['id'] ?? exp['_id']) : (exp is String ? exp : '');
    if (id.isNotEmpty && isCashierPaid(id)) {
      return true;
    }

    final s = SafeParser.getString(rawStatus).toUpperCase().trim();
    return s.contains('REJECT') ||
        s.contains('PAID') ||
        s.contains('SETTLE') ||
        s.contains('DISBURSE');
  }

  /// Returns integer (0: Submitted, 1: Manager Review, 2: Owner Signoff, 3: Settled/Paid, -1: Rejected).
  static int getStepperIndex(dynamic rawStatus, [dynamic exp]) {
    final id = exp is Map ? SafeParser.getString(exp['id'] ?? exp['_id']) : (exp is String ? exp : '');
    if (id.isNotEmpty && isCashierPaid(id)) {
      return 3;
    }

    final s = SafeParser.getString(rawStatus).toUpperCase().trim();
    if (s.contains('REJECT')) {
      return -1;
    }
    if (s.contains('PAID') || s.contains('SETTLE') || s.contains('DISBURSE')) {
      return 3;
    }
    if (s.contains('OWNER') ||
        s.contains('CASHIER') ||
        s.contains('APPROVED_2') ||
        s == 'MANAGER_APPROVED' ||
        s == 'APPROVED_1' ||
        s == 'APPROVED' ||
        s == 'APPROVED_OWNER' ||
        s == 'OWNER_APPROVED') {
      return 2;
    }
    if (s.contains('MANAGER') ||
        s.contains('LEVEL_1') ||
        s.contains('REVIEW') ||
        s == 'PENDING' ||
        s == 'SUBMITTED' ||
        s == 'PENDING_MANAGER') {
      return 1;
    }
    return 0;
  }

  static final Map<String, String> _rejectionRemarks = {};

  /// Stores a rejection remark for an expense ID so all dashboards can display it in realtime.
  static void setRejectionRemark(String expenseId, String remark) {
    if (expenseId.isNotEmpty && remark.isNotEmpty) {
      _rejectionRemarks[expenseId] = remark;
    }
  }

  /// Retrieves the rejection remark for an expense ID, with fallback to expense fields.
  static String getRejectionRemark(String expenseId, [dynamic exp]) {
    if (_rejectionRemarks.containsKey(expenseId) && _rejectionRemarks[expenseId]!.isNotEmpty) {
      return _rejectionRemarks[expenseId]!;
    }
    if (exp is Map) {
      final r = SafeParser.getString(
        exp['rejectionReason'] ?? exp['remarks'] ?? exp['comments'] ?? exp['notes'],
      );
      if (r.isNotEmpty) return r;
    }
    return 'Policy criteria not met';
  }
}
