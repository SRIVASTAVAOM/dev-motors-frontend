# Dev Motors - Google Play Store & Backend Operations History

**App Name:** Dev Motors  
**Package / Application ID:** `com.devmotors.expenses`  
**Mobile Tech Stack:** Flutter (Android `compileSdk: 36`, `targetSdk: 36`, Kotlin DSL)  
**Backend & Database:** Node.js / TypeScript + Prisma ORM + Neon Cloud PostgreSQL  
**Current Track:** Google Play Closed Testing (Alpha)  
**Last Updated:** September 20, 2026  

---

## 1. Timeline & Major Milestones

### Milestone 1: Initial Version Deployed (Sep 18, 2026)
* **Initial Release:** Dev Motors initial `.aab` (Android App Bundle) was successfully uploaded to Google Play Console under **Closed testing - Alpha**.
* **Submission Details:** Store listing, app content, and store settings were submitted and approved.
* **Status:** **Published (Green Checkmark ✅)** — Google verified the build and store listing with zero code-level rejections.

---

### Milestone 2: Testing Policy & Managed Publishing Fix (Sep 19, 2026)
* **Target Audience:** Play Store requires closed testing before general public release.
* **Google Play Policy Discovery:**
  * For this developer account, Google requires **at least 12 testers opted-in for at least 14 days** before the **"Apply for production"** button becomes active.
  * Starting status: **3 testers currently opted-in** (9 more required).
* **Issue Encountered - "App not available" for new CSV emails:**
  * User updated testers list with a new CSV file (`Closed testing - EmailData - Sheet1.csv`) and added India to target countries.
  * However, testers were seeing *"App not available / Item not found"*.
* **Root Cause Found:**
  * **Managed Publishing** was active on the Play Console.
  * All 5 changes were sitting in draft state under **"Changes not yet submitted for review"**:
    1. `Closed testing - EmailData - Sheet1.csv`
    2. `Countries / regions: Add 1 country / region: India`
    3. `Dev Motors: Start full rollout`
    4. `Track status: Resume track`
    5. `Testers: Set testers to be managed by email lists`
* **Resolution:**
  * Clicked **"Submit 5 changes for review"** on the Publishing Overview page.
  * Status transitioned to **"Changes in review"**.

---

### Milestone 3: Tester Onboarding & "Item Not Found" Troubleshooting (Sep 20, 2026)
* **Review Outcome:** Google approved the review! The CSV emails were whitelisted and the track resumed.
* **Issue Encountered - "Become a tester" appears, but "Install" button is missing or "Item not found":**
  * Testers opened the link and saw the **"Become a tester"** button, but could not install from Play Store.
* **Root Causes & Solutions:**
  1. **Two-Step Opt-in Process:**
     * The web page (`play.google.com/apps/testing/...`) is an opt-in page. After tapping **"Become a tester"**, the tester must click the blue text link: **"download it on Google Play"**.
  2. **Account Mismatch (Most Common):**
     * The phone browser may have Google Account A, while the phone's **Google Play Store App** is logged in with Google Account B.
     * **Fix:** Open Play Store app -> Tap profile photo on top-right -> Switch to the exact Gmail account added to the tester list.
  3. **Play Store Client Cache Delay:**
     * Play Store app takes 5–15 minutes to recognize newly opted-in testers.
     * **Fix:** Go to Phone Settings -> Apps -> Google Play Store -> Tap **Force Stop** and **Clear Cache**, then reopen the link.
  4. **Alternative Direct Web Install Workaround:**
     * Open `https://play.google.com/store/apps/details?id=com.devmotors.expenses` in phone Chrome browser.
     * Enable **"Desktop site"** mode in Chrome.
     * Click the direct green **"Install"** button to trigger installation on the device.

---

### Milestone 4: Database Architecture & Safe Data Management (Sep 20, 2026)
* **Database Details:**
  * **Engine:** PostgreSQL on **Neon Cloud** (`neon.tech`)
  * **Host:** `ep-still-sun-ayr9pcim-pooler.c-5.us-east-2.aws.neon.tech`
  * **Database Name:** `neondb`
  * **ORM:** Prisma Client
* **Access Method:**
  * Run in terminal: `cd backend && npx prisma studio`
  * Visual GUI opens at: `http://localhost:5555`
* **Safety & Play Store Compatibility:**
  * Editing rows, user details, expenses, or amounts via Prisma Studio updates the live database without affecting app code or breaking Play Store builds.
  * Important rules:
    - Only use valid enum values for `Role` (`EMPLOYEE`, `MANAGER`, `CASHIER`, `OWNER`) and `ExpenseStatus`.
    - Do not hardcode raw plaintext passwords in the database (they require bcrypt hashing).
    - To remove an employee with existing expense records, set `status = INACTIVE` instead of deleting the row.

---

### Milestone 5: 12 Dedicated Tester Accounts & Official PDF Generation (Sep 20, 2026)
* Created **12 dedicated dummy accounts** in the live database with common password `Dev@1234`.
* Generated a styled printable PDF:
  * **File:** `Dev_Motors_Testing_Credentials.pdf`
  * **Location:** `/Users/omsrivastava/Downloads/dev_motors_updated/Dev_Motors_Testing_Credentials.pdf`
  * **HTML Source:** `dev_motors_credentials.html`

---

### Milestone 6: Modular UI Architecture & 9-Hour Persistent Session (Sep 20, 2026)
* **Isolated Feature Branch:** `feature/modular-ui-architecture` (Main branch remains untouched with current Play Store build `1.0.0+1`).
* **9-Hour Smart Session & Auto-Login:**
  * **Problem Addressed:** Users previously had to re-enter credentials every time the app was reopened.
  * **Solution:** Added a 9-hour persistent session window (`Duration(hours: 9)`). On app launch, `SplashScreen` calls `ApiService.restoreSession()` which checks `SharedPreferences` for active token and timestamp.
  * Reopening within 9 hours automatically routes directly to the user's role dashboard (`OwnerDashboard`, `ManagerDashboard`, `CashierDashboard`, or `EmployeeDashboard`).
  * Expired sessions ($\ge 9$ hours) or manual logout automatically clear storage and navigate to `LoginPage`.
* **Modular Dashboard & Feature Enhancements:**
  * Dashboards reorganized into modular executive components with unified tokens.
  * Date/branch/status quick filters, one-tap CSV export, and receipt viewer modal in Reports.
  * Profile avatar picker supporting Camera & Gallery with base64 decoding.
  * 1-Click fast role login chips on login page.
* **Testing & Quality Assurance:**
  * Added `test/auth_session_persistence_test.dart` (4/4 tests passed).
  * Full test suite verification: **55/55 tests passed**.
  * Static analysis: `flutter analyze` $\rightarrow$ **0 issues found**.
* **Git Commit & Remote:**
  * Committed: `0c8e23d` (`feat(auth): implement 9-hour persistent session with auto-login on startup (55/55 tests passing)`).
  * Pushed to `origin/feature/modular-ui-architecture`.
  * Ready to merge into `main` when deploying the next update to Play Store / App Store.

---

## 2. Dedicated 12 Tester Accounts (Active in Database)

**Common Password for All Accounts:** `Dev@1234`

| # | Employee ID (Login) | Role | Assigned Name | Common Password | Testing Scope |
|---|---|---|---|---|---|
| 01 | `TEST01` | `EMPLOYEE` | Tester 01 | `Dev@1234` | Submit expense claims & upload receipts |
| 02 | `TEST02` | `EMPLOYEE` | Tester 02 | `Dev@1234` | Submit expense claims & upload receipts |
| 03 | `TEST03` | `EMPLOYEE` | Tester 03 | `Dev@1234` | Submit expense claims & upload receipts |
| 04 | `TEST04` | `EMPLOYEE` | Tester 04 | `Dev@1234` | Submit expense claims & upload receipts |
| 05 | `TEST05` | `EMPLOYEE` | Tester 05 | `Dev@1234` | Submit expense claims & upload receipts |
| 06 | `TEST06` | `EMPLOYEE` | Tester 06 | `Dev@1234` | Submit expense claims & upload receipts |
| 07 | `TEST07` | `MANAGER` | Tester 07 | `Dev@1234` | Approve / Reject employee expense claims |
| 08 | `TEST08` | `MANAGER` | Tester 08 | `Dev@1234` | Approve / Reject employee expense claims |
| 09 | `TEST09` | `MANAGER` | Tester 09 | `Dev@1234` | Approve / Reject employee expense claims |
| 10 | `TEST10` | `CASHIER` | Tester 10 | `Dev@1234` | Mark approved claims as Paid & settle cash |
| 11 | `TEST11` | `CASHIER` | Tester 11 | `Dev@1234` | Mark approved claims as Paid & settle cash |
| 12 | `TEST12` | `OWNER` | Tester 12 | `Dev@1234` | Executive Dashboard, analytics & reports |

---

## 3. Standard Operating Procedure (SOP) for Testers

Share these exact instructions with testers:

1. **Check Play Store Account:** Open Google Play Store on your phone and ensure your profile photo shows your invited Gmail address.
2. **Open Web Testing Link:** Open the invite link:  
   👉 `https://play.google.com/apps/testing/com.devmotors.expenses`
3. **Click "Become a tester":** Page will reload and confirm: *"Welcome to the testing program"*.
4. **Click "download it on Google Play":** Tap the blue link to open Google Play Store.
5. **Install & Login:** Tap green **Install**, open the app, enter your assigned Employee ID (`TEST01`–`TEST12`), and password `Dev@1234`.
6. **Keep Installed for 14 Days:** **Do not uninstall the app** for 14 continuous days so Google's closed testing requirement completes.

---

## 4. Google Play vs Apple App Store Comparison

| Feature | Google Play Store | Apple App Store |
|---|---|---|
| **Mandatory Testing Period** | **Yes** (12 testers for 14 continuous days) | **No** (Can submit for public release immediately on Day 1) |
| **Beta Testing Tool** | Closed Testing track (Web invite link + Play Store) | **TestFlight** (Clean iOS app with single-click install link) |
| **Account Cost** | $25 one-time lifetime fee | $99/year recurring subscription |
| **Build Machine** | Any OS (Mac/Windows/Linux) | Mac OS + Xcode required |
| **App Review Strictness** | Automated bot + policy checks | Strict human inspection (requires Delete Account button if auth exists) |

---

## 5. Roadmap to Public Release (Production Track)

1. **Maintain 12 Active Testers:** Ensure `12 testers currently opted-in` status remains on the Play Console Dashboard.
2. **Complete 14-Day Cycle:** Let the 14-day timer run its course without removing testers.
3. **Apply for Production:**
   * Once 14 days finish, click the blue **"Apply for production"** button on the Dashboard.
   * Fill out the standard feedback questionnaire.
4. **Promote Release to Production:** Promote the approved Alpha release directly to the **Production** track.
5. **Public Launch:** Following Google's final production review (1–3 days), Dev Motors will be publicly visible and downloadable on Google Play Store worldwide.

---

## 6. Future Release Procedure (Updates & Bug Fixes)

When deploying future updates:
1. Bump version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2 # (major.minor.patch+buildNumber)
   ```
2. Generate release app bundle:
   ```bash
   flutter build appbundle --release
   ```
3. In Play Console -> Navigate to **Closed testing** (or **Production**) -> **Create new release**.
4. Upload `build/app/outputs/bundle/release/app-release.aab`.
5. Enter release notes, save, and go to **Publishing overview** -> click **"Send for review"**.
