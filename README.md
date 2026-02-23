# SmartGate+: Android-Based Digital Gate Pass Management System

SmartGate+ is a professional digital gate pass management system designed for academic institutions to streamline the student leave process. It replaces traditional paper-based methods with a secure, role-based, QR-enabled mobile application.

## Table of Contents
1. [Problem Statement](#problem-statement)
2. [Project Overview](#project-overview)
3. [System Architecture](#system-architecture)
4. [Features](#features)
5. [Tech Stack](#tech-stack)
6. [Folder Structure](#folder-structure)
7. [Installation Steps](#installation-steps)
8. [Firebase Configuration](#firebase-configuration)
9. [Database Structure](#database-structure)
10. [Approval Workflow](#approval-workflow)
11. [QR Validation Flow](#qr-validation-flow)
12. [Screenshots](#screenshots)
13. [Future Enhancements](#future-enhancements)
14. [Contributors](#contributors)
15. [License](#license)

---

## Problem Statement
Traditional gate pass systems in colleges rely heavily on physical registers and signed paper slips. This process is time-consuming, difficult to audit, and prone to loss or forgery. Students often face delays waiting for multiple faculty signatures, and security personnel have no real-time way to verify the authenticity of a pass.

## Project Overview
SmartGate+ leverages cloud technology and QR encryption to provide an end-to-end digital solution. The system integrates multiple stakeholders—Students, Staff Advisors, HODs, and Security—into a unified platform, ensuring transparency and accountability in real-time.

## System Architecture
The application follows a modular architecture using the Provider pattern for state management.
- **Frontend Layer**: Built with Flutter (Material 3) for a responsive and modern UI.
- **Service Layer**: Decoupled AuthService and Database classes for handling Firebase logic.
- **Data Layer**: Cloud Firestore for real-time data persistence and Firebase Auth for secure identity management.

## Features
- **Email/Password Authentication**: Secure login and sign-up with password encryption via Firebase.
- **Role-Based Access Control (RBAC)**: Unique dashboards and permissions for Students, Staff, HOD, and Security.
- **Multi-Level Approval Workflow**: Sequential approval logic (Advisor -> HOD).
- **Dynamic QR Generation**: Encrypted QR codes generated only for fully approved passes.
- **Real-Time Scanner**: Integrated scanner for security personnel with instant validation.
- **Cloud-Based Database**: No local storage involved; all data is synced across devices in real-time.

## Tech Stack
- **Frontend**: Flutter (3.x)
- **Logic**: Dart
- **Authentication**: Firebase Auth
- **Backend Database**: Cloud Firestore
- **QR Engine**: qr_flutter & mobile_scanner
- **Typography**: Google Fonts (Outfit)

## Folder Structure
```text
lib/
├── core/
│   └── app_theme.dart       # Global design system & tokens
├── models/
│   ├── user_role.dart       # User enums and role logic
│   └── gate_pass.dart       # Gate pass request entity
├── providers/
│   ├── auth_provider.dart    # Authentication state management
│   └── gate_pass_provider.dart # Business logic for requests
├── services/
│   └── auth_service.dart    # Firebase Auth & Firestore CRUD
├── screens/
│   ├── auth/                # Login, Register, Complete Profile
│   ├── student/             # Student dashboard & Request forms
│   ├── staff/               # Staff approval dashboard
│   ├── hod/                 # HOD department dashboard
│   └── security/            # QR Scanner & Result views
└── main.dart                # App entry & Root routing logic
```

## Installation Steps
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/smart_gate_pass.git
   cd smart_gate_pass
   ```
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Firebase Setup**:
   - Follow the instructions in the [Firebase Configuration](#firebase-configuration) section.
4. **Run the Project**:
   ```bash
   flutter run
   ```

## Firebase Configuration
1. Create a new project in the [Firebase Console](https://console.firebase.google.com/).
2. Add an Android app with the package name `com.lbt.gatepass`.
3. Download the `google-services.json` file and place it in the `android/app/` directory.
4. Enable **Email/Password** authentication in the Firebase Auth tab.
5. Create a **Firestore Database** in test mode and set your region.

## Database Structure
### users collection
```json
{
  "uid": "USER_ID",
  "name": "Full Name",
  "email": "email@college.edu",
  "role": "student/staff/hod/security",
  "department": "CSE/ECE/...",
  "registerNumber": "ST001",
  "phone": "9876543210"
}
```
### gate_passes collection
```json
{
  "id": "PASS_ID",
  "studentId": "UID",
  "reason": "Medical/Personal",
  "date": "Timestamp",
  "fromTime": "10:30 AM",
  "toTime": "02:30 PM",
  "status": "pending/approved/rejected"
}
```

## Approval Workflow
1. **Request Submission**: Student fills the form with details and reason.
2. **Staff Verification**: Staff Advisor reviews the pending request and approves/rejects.
3. **HOD Finalization**: HOD sees the departmental approval list and gives the final clearance.
4. **Status Update**: Real-time notification/status change updated on Student Dashboard.

## QR Validation Flow
1. **Generation**: If `status == "approved"`, the Student Dashboard displays a "Show QR" button.
2. **Scanning**: Security uses the in-app scanner to scan the student's QR code.
3. **Verification**: The system verifies the ID against Firestore and checks if the current time falls within the validity window.
4. **Result**: Visual feedback (Green for Success, Red for Invalid/Rejected, Orange for Expired).

## Screenshots
*Screenshots will be uploaded upon deployment.*
![Login Screen](https://via.placeholder.com/300x600?text=Login+Screen)
![Student Dashboard](https://via.placeholder.com/300x600?text=Student+Dashboard)
![Security Scanner](https://via.placeholder.com/300x600?text=Security+Scanner)

## Future Enhancements
- Integration with SMS API for parental notifications.
- Attendance system synchronization.
- Support for guest/parent passes.
- Face Recognition for enhanced security during scanner validation.

## Contributors
- **Author**: Your Name / Team Name

## License
Distributed under the MIT License. See `LICENSE` for more information.
