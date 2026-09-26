# Dev Motors - Dealership Expense Management System

> **Official Repository Architecture, Feature-to-File Map & Maintenance Guide**  
> **Mobile Stack:** Flutter (Android `targetSdk: 36` | iOS Swift / Official Xcode 27 GM)  
> **Backend Stack:** Node.js / TypeScript + Express + Prisma ORM + Neon Cloud PostgreSQL  
> **Live Deployments:**  
> - **Apple App Store:** `v1.0 (Build 5)` Submitted & In Queue (**Waiting for Review**)  
> - **Google Play Store:** `v1.0.2 (Build 3)` Active in Closed Testing  

---

## 📌 Master Feature-to-File Directory (Feature Map)

Jab bhi in future kisi **specific feature** me change ya update karna ho, aapko pure application ko chhedne ki zaroorat nahi hai. Har feature isolated folder me bana hua hai:

### 1. 🔐 Authentication & Session (Login, Logout, Auto-Login)
| Kya update karna hai? | Specific File Path |
| :--- | :--- |
| **Login Screen & UI** | [`lib/features/auth/presentation/pages/login_page.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/auth/presentation/pages/login_page.dart) |
| **Login Form & Inputs** | [`lib/features/auth/presentation/widgets/login_form.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/auth/presentation/widgets/login_form.dart) |
| **Forgot Password Dialog** | [`lib/features/auth/presentation/pages/forgot_password_dialog.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/auth/presentation/pages/forgot_password_dialog.dart) |
| **Splash Screen & Auto-Login** | [`lib/features/auth/presentation/pages/splash_screen.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/auth/presentation/pages/splash_screen.dart) |
| **Auth State & Token Cache** | [`lib/features/auth/presentation/providers/auth_provider.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/auth/presentation/providers/auth_provider.dart) |
| **User Roles Enum** | [`lib/features/auth/domain/entities/user_role.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/auth/domain/entities/user_role.dart) |

---

### 2. 📱 Role-Based Dashboards
| Role | Specific File Path |
| :--- | :--- |
| **Employee Dashboard** | [`lib/features/dashboard/presentation/pages/employee_dashboard.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/dashboard/presentation/pages/employee_dashboard.dart) |
| **Manager Dashboard** | [`lib/features/dashboard/presentation/pages/manager_dashboard.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/dashboard/presentation/pages/manager_dashboard.dart) |
| **Cashier Dashboard** | [`lib/features/dashboard/presentation/pages/cashier_dashboard.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/dashboard/presentation/pages/cashier_dashboard.dart) |
| **Owner Executive Dashboard** | [`lib/features/dashboard/presentation/pages/owner_dashboard.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/dashboard/presentation/pages/owner_dashboard.dart) |
| **Dashboard Drawer / Menu** | [`lib/features/dashboard/presentation/widgets/dashboard_drawer.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/dashboard/presentation/widgets/dashboard_drawer.dart) |
| **Metrics / Summary Cards** | [`lib/features/dashboard/presentation/widgets/summary_card.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/dashboard/presentation/widgets/summary_card.dart) |

---

### 3. 💸 Expenses & Receipts
| Kya update karna hai? | Specific File Path |
| :--- | :--- |
| **Add New Expense Page** | [`lib/features/expenses/presentation/pages/add_expense_page.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/expenses/presentation/pages/add_expense_page.dart) |
| **Expense Details Screen** | [`lib/features/expenses/presentation/pages/expense_details_page.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/expenses/presentation/pages/expense_details_page.dart) |
| **All Expenses List Page** | [`lib/features/expenses/presentation/pages/expenses_page.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/expenses/presentation/pages/expenses_page.dart) |
| **Camera & Receipt Upload** | [`lib/features/expenses/presentation/widgets/receipt_upload.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/expenses/presentation/widgets/receipt_upload.dart) |
| **Receipt Image Viewer Modal** | [`lib/features/expenses/presentation/widgets/receipt_viewer_dialog.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/expenses/presentation/widgets/receipt_viewer_dialog.dart) |
| **Approval Stepper Widget** | [`lib/features/expenses/presentation/widgets/approval_stepper.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/expenses/presentation/widgets/approval_stepper.dart) |
| **Categories & Status Chips** | [`lib/features/expenses/presentation/widgets/category_chip.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/expenses/presentation/widgets/category_chip.dart) |

---

### 4. 👥 Approvals & Workflows
| Kya update karna hai? | Specific File Path |
| :--- | :--- |
| **Manager Approvals Page** | [`lib/features/approvals/presentation/pages/manager_approvals_page.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/approvals/presentation/pages/manager_approvals_page.dart) |
| **Approval Action Buttons** | [`lib/features/expenses/presentation/widgets/action_buttons.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/expenses/presentation/widgets/action_buttons.dart) |

---

### 5. 📊 Reports, Analytics & CSV Export
| Kya update karna hai? | Specific File Path |
| :--- | :--- |
| **Reports Main Page** | [`lib/features/reports/presentation/pages/reports_page.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/reports/presentation/pages/reports_page.dart) |
| **Report Details View** | [`lib/features/reports/presentation/pages/report_details_page.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/reports/presentation/pages/report_details_page.dart) |
| **Bar / Pie Charts** | [`lib/features/reports/presentation/widgets/expense_bar_chart.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/reports/presentation/widgets/expense_bar_chart.dart) |
| **CSV Export Engine** | [`lib/core/services/csv_export_service.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/core/services/csv_export_service.dart) |

---

### 6. ⚙️ Settings, Profile & Password
| Kya update karna hai? | Specific File Path |
| :--- | :--- |
| **Settings Screen** | [`lib/features/settings/presentation/pages/settings_page.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/settings/presentation/pages/settings_page.dart) |
| **Profile View & Edit** | [`lib/features/profile/presentation/pages/profile_page.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/profile/presentation/pages/profile_page.dart) |
| **Change Password Modal** | [`lib/features/profile/presentation/widgets/change_password_dialog.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/features/profile/presentation/widgets/change_password_dialog.dart) |

---

### 7. 🌐 Central Core Services (Network & Routing)
| Service | Specific File Path |
| :--- | :--- |
| **Central HTTP / API Client** | [`lib/core/services/api_service.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/core/services/api_service.dart) |
| **App Routing & Navigation** | [`lib/core/router/app_router.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/core/router/app_router.dart) |
| **Color Tokens & Constants** | [`lib/core/constants/colors.dart`](file:///Users/omsrivastava/Downloads/dev_motors_updated/lib/core/constants/colors.dart) |

---

### 8. 🗄️ Backend API & Database (Node.js + Prisma)
| Kya update karna hai? | Specific File Path |
| :--- | :--- |
| **Database Schema (Tables/Columns)** | [`backend/prisma/schema.prisma`](file:///Users/omsrivastava/Downloads/dev_motors_updated/backend/prisma/schema.prisma) |
| **Express Server Entrypoint** | [`backend/src/server.ts`](file:///Users/omsrivastava/Downloads/dev_motors_updated/backend/src/server.ts) |
| **Authentication Controllers** | [`backend/src/controllers/auth.controller.ts`](file:///Users/omsrivastava/Downloads/dev_motors_updated/backend/src/controllers/auth.controller.ts) |
| **Expense & Routing Controllers** | [`backend/src/controllers/expense.controller.ts`](file:///Users/omsrivastava/Downloads/dev_motors_updated/backend/src/controllers/expense.controller.ts) |
| **Open Prisma Database GUI** | Run in terminal: `cd backend && npx prisma studio` (Opens at `http://localhost:5555`) |

---

## 🛡️ Future Safe-Development Rules (Bina App Tode Update Kaise Karein)

1. **Modify Only One Feature Folder:**
   * Example: Agar sirf Expense add karne ka form change karna hai, toh sirf `lib/features/expenses/` ke andar change karein. Core network ya Auth files ko chhedne ki zaroorat nahi hai.
2. **Run Integrity Check Before Build:**
   ```bash
   flutter analyze   # Must show: "No issues found!"
   flutter test      # Must show: "All tests passed!"
   ```
3. **Always Increment Build Number in `pubspec.yaml`:**
   ```yaml
   version: 1.0.3+6  # (1.0.3 is display name, 6 is internal build number)
   ```
4. **Build Release Commands:**
   * **Android Play Store:**
     ```bash
     flutter build appbundle --release
     # Output: build/app/outputs/bundle/release/app-release.aab
     ```
   * **iOS App Store:**
     ```bash
     flutter build ios --release --no-codesign
     xcodebuild archive -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination 'generic/platform=iOS' -archivePath build/ios/archive/Runner.xcarchive -allowProvisioningUpdates
     xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive -exportOptionsPlist build/ios/ipa/ExportOptions.plist -exportPath build/ios/ipa -allowProvisioningUpdates
     # Output: build/ios/ipa/dev_motors.ipa (Drag & drop into Transporter)
     ```

---

## 📜 Full Operations & Deployment History
Complete milestone history, tester accounts, and store procedures are documented in:  
👉 [`PLAY_STORE_DEPLOYMENT_HISTORY.md`](file:///Users/omsrivastava/Downloads/dev_motors_updated/PLAY_STORE_DEPLOYMENT_HISTORY.md)
