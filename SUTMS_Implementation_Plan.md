# Smart University Transport Management System (SUTMS)
## Detailed Implementation Plan — University of Gwadar
**Team:** Sajida Abdullah · Sadia Abdul Waheed · Khadija Maqbool  
**Supervisor:** Nasir Ali  
**Registration Term:** Spring 2026

---

## Table of Contents

1. [Recommended Technology Stack](#1-recommended-technology-stack)
2. [System Architecture](#2-system-architecture)
3. [Database Design](#3-database-design)
4. [Backend Implementation](#4-backend-implementation)
5. [Frontend / Mobile App Screens](#5-frontend--mobile-app-screens)
6. [Feature-by-Feature Implementation](#6-feature-by-feature-implementation)
7. [Phase-wise Development Plan](#7-phase-wise-development-plan)
8. [Folder Structure](#8-folder-structure)
9. [API Endpoints Reference](#9-api-endpoints-reference)
10. [Testing Plan](#10-testing-plan)
11. [Deployment Plan](#11-deployment-plan)
12. [Risk & Mitigation](#12-risk--mitigation)

---

## 1. Recommended Technology Stack

> **Why we are changing the stack from the proposal:** The proposal listed Flutter + Firebase + MongoDB. This combination has a fundamental mismatch — Firebase already includes Firestore (a NoSQL document database), and mixing it with a separately hosted MongoDB instance creates unnecessary complexity for a student FYP. The stack below is simpler, cohesive, free-tier friendly, and very well documented for beginners.

### Final Stack Decision

| Layer | Technology | Reason |
|---|---|---|
| **Mobile Frontend** | Flutter (Dart) | Cross-platform iOS/Android, excellent UI, huge community |
| **Backend** | Firebase (all-in-one) | Auth, Firestore DB, Storage, Cloud Messaging — all in one console, no separate server needed |
| **Database** | Cloud Firestore | Real-time updates, NoSQL, works natively with Firebase Auth |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Already part of Firebase, free tier is sufficient |
| **Authentication** | Firebase Authentication | Supports email/password, easy role management |
| **File Storage** | Firebase Storage | For profile pictures, uploaded files if needed |
| **Maps / GPS** | Google Maps Flutter Plugin | Free quota, best Flutter integration |
| **State Management** | Provider (Flutter) | Simplest and most beginner-friendly state manager |
| **Version Control** | GitHub | Industry standard |
| **Project Management** | Trello | Already in proposal, easy to use |
| **IDE** | VS Code + Android Studio | Flutter development standard setup |

### Why NOT separate MongoDB?
- MongoDB requires a separately hosted server (Atlas or self-hosted)
- Firebase Firestore does everything MongoDB does for this scale
- Fewer services = fewer failure points = easier for a 3-person team
- Firebase free tier (Spark Plan) is more than enough for a university pilot

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     MOBILE APPLICATION (Flutter)                │
│                                                                 │
│  ┌──────────┐   ┌──────────────┐   ┌───────────────────────┐   │
│  │ Student  │   │ Bus Driver   │   │  Transport Admin      │   │
│  │  View    │   │    View      │   │       Panel           │   │
│  └────┬─────┘   └──────┬───────┘   └───────────┬───────────┘   │
│       │                │                        │               │
│       └────────────────┴────────────────────────┘               │
│                        │                                        │
│              Firebase SDK (Dart)                                │
└────────────────────────┼────────────────────────────────────────┘
                         │ HTTPS / WebSocket
┌────────────────────────▼────────────────────────────────────────┐
│                     FIREBASE BACKEND                            │
│                                                                 │
│  ┌─────────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │  Firebase Auth  │  │  Cloud Firestore  │  │  Firebase     │  │
│  │  (Email/Role)   │  │  (Main Database)  │  │  Storage      │  │
│  └─────────────────┘  └──────────────────┘  └───────────────┘  │
│                                                                 │
│  ┌─────────────────┐  ┌──────────────────┐                     │
│  │  Firebase Cloud │  │  Cloud Functions  │                     │
│  │  Messaging(FCM) │  │  (Auto triggers)  │                     │
│  └─────────────────┘  └──────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│               GOOGLE MAPS PLATFORM API                          │
│         (Route display, live driver location)                   │
└─────────────────────────────────────────────────────────────────┘
```

### Architecture Pattern: MVVM (Model-View-ViewModel)
- **Model** → Firestore data classes (Route, Bus, User, Notice)
- **ViewModel** → Provider classes managing business logic
- **View** → Flutter widgets / screens

---

## 3. Database Design

All data is stored in **Cloud Firestore** (NoSQL). Firestore uses Collections → Documents → Fields.

---

### 3.1 Collection: `universities`

```
universities/
  {universityId}/
    name: "University of Gwadar"
    city: "Gwadar"
    country: "Pakistan"
    logoUrl: "https://..."
    createdAt: Timestamp
    isActive: true
```

---

### 3.2 Collection: `users`

```
users/
  {userId}/              ← same as Firebase Auth UID
    uid: "abc123"
    name: "Sajida Abdullah"
    email: "sajida@uog.edu.pk"
    phone: "03091088710"
    role: "student"      ← "student" | "driver" | "admin"
    universityId: "uog"
    profilePhotoUrl: ""
    assignedRouteId: ""  ← for drivers only
    regNumber: ""        ← for students only
    fcmToken: "xyz..."   ← for push notifications
    createdAt: Timestamp
    isActive: true
```

---

### 3.3 Collection: `routes`

```
routes/
  {routeId}/
    universityId: "uog"
    routeName: "Route A – Gwadar City Centre"
    routeNumber: "A"
    startPoint: "City Centre"
    endPoint: "University of Gwadar"
    stops: [
      { stopName: "Gwadar Bus Stand", lat: 25.1234, lng: 62.3456, order: 1 },
      { stopName: "Fish Harbour", lat: 25.1300, lng: 62.3500, order: 2 },
      { stopName: "UoG Main Gate", lat: 25.1450, lng: 62.3600, order: 3 }
    ]
    totalDistance: "12 km"
    estimatedDuration: "30 min"
    isActive: true
    createdAt: Timestamp
    updatedAt: Timestamp
```

---

### 3.4 Collection: `buses`

```
buses/
  {busId}/
    universityId: "uog"
    busNumber: "UOG-001"
    capacity: 40
    assignedRouteId: "routeA"
    assignedDriverId: "userId123"
    isActive: true
    createdAt: Timestamp
```

---

### 3.5 Collection: `schedules`

```
schedules/
  {scheduleId}/
    universityId: "uog"
    routeId: "routeA"
    busId: "busUOG001"
    driverId: "driverUserId"
    direction: "toUniversity"   ← "toUniversity" | "fromUniversity"
    departureTime: "07:30"
    arrivalTime: "08:00"
    daysOfWeek: ["Monday","Tuesday","Wednesday","Thursday","Friday"]
    isActive: true
    createdAt: Timestamp
    updatedAt: Timestamp
```

---

### 3.6 Collection: `notices`

```
notices/
  {noticeId}/
    universityId: "uog"
    title: "Bus Route A Delay Today"
    body: "Due to road construction, Route A will be delayed by 20 minutes."
    type: "delay"    ← "delay" | "cancellation" | "general" | "emergency"
    targetRole: "all"  ← "all" | "student" | "driver"
    postedBy: "adminUserId"
    isActive: true
    createdAt: Timestamp
    expiresAt: Timestamp
```

---

### 3.7 Collection: `liveLocations`

```
liveLocations/
  {driverUserId}/
    lat: 25.1340
    lng: 62.3512
    routeId: "routeA"
    busId: "busUOG001"
    isOnDuty: true
    lastUpdated: Timestamp    ← updated every 5 seconds by driver app
    speed: 40                 ← km/h
```

---

### 3.8 Collection: `feedback`

```
feedback/
  {feedbackId}/
    universityId: "uog"
    submittedBy: "studentUserId"
    routeId: "routeA"
    rating: 4              ← 1 to 5
    comment: "Bus was on time today, great service."
    createdAt: Timestamp
```

---

### 3.9 Firestore Security Rules (Overview)

```
// Only authenticated users can read their university data
// Only admins can write routes, schedules, notices
// Drivers can only update their own liveLocation document
// Students can only read, not write core data
```

---

## 4. Backend Implementation

The backend is **100% serverless using Firebase**. No separate server or Node.js backend is needed. Logic is handled through:

1. **Firebase Auth** — handles login, logout, role checking via custom claims
2. **Firestore** — all CRUD operations done directly from Flutter SDK
3. **Cloud Functions** — automated tasks (triggered by Firestore events)
4. **FCM** — push notifications triggered by Cloud Functions

---

### 4.1 Firebase Authentication Setup

**Steps:**
1. Enable Email/Password sign-in in Firebase Console
2. On registration, save user in both Firebase Auth and Firestore `users` collection
3. After login, read user's `role` field from Firestore to determine which screen to show

**Role Routing Logic (Flutter):**
```dart
// After login, check role and route accordingly
if (user.role == 'admin')   → AdminDashboardScreen
if (user.role == 'driver')  → DriverDashboardScreen
if (user.role == 'student') → StudentHomeScreen
```

---

### 4.2 Firebase Cloud Functions (Automated Tasks)

These are small JavaScript functions deployed to Firebase that run automatically.

| Function | Trigger | Action |
|---|---|---|
| `onNewNotice` | New document in `notices/` | Send FCM push notification to all university students |
| `onScheduleUpdate` | Update in `schedules/` | Notify affected students about time change |
| `cleanupExpiredNotices` | Scheduled (daily midnight) | Delete notices past `expiresAt` |
| `onDriverLocationUpdate` | Update in `liveLocations/` | Calculate ETA and update route document |

---

### 4.3 Cloud Firestore Data Access Patterns (Flutter)

**Real-time stream (used for live tracking and notices):**
```dart
FirebaseFirestore.instance
  .collection('liveLocations')
  .doc(driverId)
  .snapshots()
  .listen((snapshot) {
    // Update map marker in real-time
  });
```

**One-time fetch (used for routes, schedules):**
```dart
final snapshot = await FirebaseFirestore.instance
  .collection('routes')
  .where('universityId', isEqualTo: currentUser.universityId)
  .where('isActive', isEqualTo: true)
  .get();
```

---

## 5. Frontend / Mobile App Screens

All screens built in **Flutter**. Navigation handled by `GoRouter` package.

---

### 5.1 Screen Map

```
App Launch
    │
    ├── Splash Screen
    │
    ├── Onboarding Screen (first launch only)
    │
    ├── Login Screen
    │       └── Forgot Password Screen
    │
    └── Role-based Navigation
            │
            ├── STUDENT
            │     ├── Home Screen (tabs)
            │     │     ├── Tab 1: My Routes
            │     │     ├── Tab 2: Live Tracker
            │     │     ├── Tab 3: Notices
            │     │     └── Tab 4: Profile
            │     ├── Route Detail Screen
            │     ├── Bus Schedule Screen
            │     ├── Live Map Screen
            │     ├── Notice Detail Screen
            │     └── Feedback Screen
            │
            ├── DRIVER
            │     ├── Driver Dashboard
            │     ├── My Route Screen
            │     ├── Start/End Duty Screen (toggles live location sharing)
            │     ├── Notices Screen
            │     └── Driver Profile Screen
            │
            └── ADMIN
                  ├── Admin Dashboard (stats overview)
                  ├── Manage Routes Screen
                  │     ├── Add Route Screen
                  │     └── Edit Route Screen
                  ├── Manage Schedules Screen
                  │     ├── Add Schedule Screen
                  │     └── Edit Schedule Screen
                  ├── Manage Users Screen
                  │     ├── Student List
                  │     └── Driver List
                  ├── Manage Buses Screen
                  ├── Post Notice Screen
                  ├── Notices List Screen
                  └── Admin Profile Screen
```

---

### 5.2 Screen-by-Screen Specification

---

#### SCREEN 01 — Splash Screen
- **Purpose:** App loads, checks if user is logged in
- **Duration:** 2 seconds
- **Logic:** If logged in → route to correct dashboard based on role; if not → Login Screen
- **UI Elements:** University logo, app name, loading spinner

---

#### SCREEN 02 — Onboarding Screen
- **Purpose:** Show app features to new users (shown only on first install)
- **UI Elements:** 3-slide carousel with illustrations, "Get Started" button on last slide
- **Slides:**
  1. "Check your bus routes anytime"
  2. "Get live updates and notifications"
  3. "Track your bus in real time"

---

#### SCREEN 03 — Login Screen
- **Fields:** Email, Password
- **Buttons:** Login, Forgot Password
- **Validation:** Email format check, password minimum 6 characters
- **Error Handling:** Show SnackBar for wrong credentials
- **Note:** No self-registration for students — admin creates accounts

---

#### SCREEN 04 — Student Home Screen (Bottom Nav Bar)
- **Tab 1 – My Routes:**
  - List of all active bus routes for the university
  - Each card shows: route number, route name, start–end points
  - Tap to open Route Detail Screen

- **Tab 2 – Live Tracker:**
  - Google Map with driver marker
  - Dropdown to select which route to track
  - Shows estimated arrival time
  - Driver marker moves in real-time (every 5 seconds)

- **Tab 3 – Notices:**
  - Scrollable list of notices (latest first)
  - Color-coded by type: red = emergency, orange = delay, blue = general
  - Tap to open Notice Detail Screen

- **Tab 4 – Profile:**
  - Student name, reg number, university, profile photo
  - Logout button
  - Submit Feedback button

---

#### SCREEN 05 — Route Detail Screen
- **Shows:**
  - Route number and name
  - List of all stops in order (with icons)
  - Direction: To University / From University toggle
  - View Schedule button
  - View on Map button

---

#### SCREEN 06 — Bus Schedule Screen
- **Shows:**
  - Schedule for selected route
  - Table: Stop Name | Departure Time | Days
  - Direction toggle (To University / From University)

---

#### SCREEN 07 — Live Map Screen
- **Shows:**
  - Full-screen Google Map
  - Bus route polyline drawn on map
  - Driver's live marker (bus icon)
  - Student's current location marker
  - ETA chip at bottom: "Bus arrives in ~8 minutes"
- **Data source:** Real-time Firestore stream from `liveLocations/`

---

#### SCREEN 08 — Notice Detail Screen
- **Shows:** Full notice title, body text, posted date, type badge

---

#### SCREEN 09 — Feedback Screen
- **Fields:** Select Route (dropdown), Rating (1–5 stars), Comment (text area)
- **Button:** Submit Feedback
- **Validation:** Route must be selected, rating required

---

#### SCREEN 10 — Driver Dashboard
- **Shows:**
  - My assigned route name and number
  - Today's schedule (departure time, stops)
  - Start Duty / End Duty toggle button (large, prominent)
  - When "Start Duty" is ON → app shares GPS location every 5 seconds to Firestore
  - Latest notices section

---

#### SCREEN 11 — Driver Start/End Duty Screen
- **Start Duty:** Activates GPS sharing, updates `liveLocations/{driverId}` with `isOnDuty: true`
- **End Duty:** Stops GPS sharing, sets `isOnDuty: false`
- **Warning dialog** before ending duty if students are likely in transit

---

#### SCREEN 12 — Admin Dashboard
- **Stats Cards:**
  - Total Routes | Total Buses | Total Students | Total Drivers
  - Active notices count
- **Quick Actions:** Post Notice, Add Route, Manage Users

---

#### SCREEN 13 — Manage Routes Screen
- List of all routes (swipeable cards)
- Swipe left to delete, tap to edit
- FAB (+) button to add new route

---

#### SCREEN 14 — Add / Edit Route Screen
- **Fields:**
  - Route Name, Route Number
  - Start Point, End Point
  - Add Stops (dynamic list — tap + to add a stop, enter name, lat, lng, order)
  - Total Distance, Estimated Duration
  - Active toggle
- **Button:** Save Route (writes to Firestore `routes/`)

---

#### SCREEN 15 — Manage Schedules Screen
- List of schedules grouped by route
- Tap to edit
- FAB to add new schedule

---

#### SCREEN 16 — Add / Edit Schedule Screen
- **Fields:**
  - Select Route (dropdown)
  - Select Bus (dropdown)
  - Select Driver (dropdown)
  - Direction (To University / From University)
  - Departure Time (time picker)
  - Arrival Time (time picker)
  - Days of Week (multi-select checkboxes)

---

#### SCREEN 17 — Manage Users Screen
- Two tabs: Students | Drivers
- List with name, reg number, assigned route (for drivers)
- Tap to view/edit user details
- FAB to add new user (admin creates accounts, not self-registration)

---

#### SCREEN 18 — Manage Buses Screen
- List of buses with bus number, capacity, assigned route, assigned driver
- Tap to edit, FAB to add new bus

---

#### SCREEN 19 — Post Notice Screen
- **Fields:**
  - Title
  - Body / Message
  - Type (dropdown: Delay / Cancellation / General / Emergency)
  - Target Audience (All / Students / Drivers)
  - Expiry Date (date picker)
- **Button:** Post Notice → writes to Firestore → triggers Cloud Function → sends FCM

---

#### SCREEN 20 — Notices List Screen (Admin)
- All posted notices with edit/delete options
- Filter by type

---

## 6. Feature-by-Feature Implementation

### Feature 1: Role-Based Authentication

**Files:** `lib/services/auth_service.dart`, `lib/screens/login_screen.dart`

**Steps:**
1. User enters email + password
2. Firebase Auth signs in
3. App fetches user document from `users/{uid}`
4. Reads `role` field
5. Navigates to correct screen using GoRouter

**Custom Claims (Optional Advanced):** Set `role` as a custom claim in Firebase Auth so it's available in the token without a Firestore read. Implement via Cloud Function that triggers on user creation.

---

### Feature 2: Live Bus Tracking

**Files:** `lib/screens/live_map_screen.dart`, `lib/services/location_service.dart`

**Driver side:**
1. Driver presses "Start Duty"
2. Flutter's `geolocator` package starts a position stream
3. Every 5 seconds, write lat/lng to `liveLocations/{driverId}`

**Student side:**
1. Student opens Live Tracker tab
2. App opens a Firestore `snapshots()` stream on `liveLocations/{driverId}`
3. On each new snapshot, update the marker on Google Map
4. Calculate estimated arrival using distance from driver to student's stop

**Packages needed:**
- `google_maps_flutter`
- `geolocator`
- `cloud_firestore`

---

### Feature 3: Push Notifications (FCM)

**Flow:**
1. On login, app gets FCM token and saves it to `users/{uid}/fcmToken`
2. Admin posts a notice → Firestore document created
3. Cloud Function `onNewNotice` fires
4. Function fetches all FCM tokens for the target university
5. Sends FCM multicast message

**Flutter side:** Use `firebase_messaging` package to handle foreground, background, and terminated app notifications.

---

### Feature 4: Schedule Viewing

- Admin creates schedules in Firestore
- Student taps a route → navigates to Schedule Screen
- App queries `schedules` collection filtered by `routeId` and `isActive: true`
- Displays in a clean table grouped by direction and day

---

### Feature 5: Notices / Announcements

- Admin posts a notice from the Post Notice Screen
- Students see notices in real-time (Firestore stream) in the Notices tab
- FCM notification delivered to student's device
- Notices auto-expire based on `expiresAt` timestamp (Cloud Function cleans up)

---

### Feature 6: Multi-University Support

- Every document in every collection includes a `universityId` field
- All queries are filtered by `universityId: currentUser.universityId`
- Different universities are completely isolated from each other's data
- Adding a new university = create a new document in `universities/` + create admin user

---

## 7. Phase-wise Development Plan

### Phase 1 — Setup & Design (Week 1–2)

| Task | Owner | Details |
|---|---|---|
| Create Firebase project | All | Enable Auth, Firestore, Storage, FCM |
| Add university data | Sajida | Add UoG document to Firestore |
| Design all wireframes | Khadija | Use Figma (free) for all 20 screens |
| Setup Flutter project | Sadia | `flutter create sutms`, add all dependencies to `pubspec.yaml` |
| Setup GitHub repo | All | Create repo, add `.gitignore`, set up branches |
| Configure GoRouter | Sadia | Set up navigation routes |
| Configure Trello board | All | Create cards for each task |

**pubspec.yaml dependencies to add:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_messaging: ^14.7.9
  firebase_storage: ^11.5.6
  google_maps_flutter: ^2.5.3
  geolocator: ^10.1.0
  provider: ^6.1.1
  go_router: ^13.0.1
  cached_network_image: ^3.3.1
  intl: ^0.18.1
  flutter_local_notifications: ^16.3.0
```

---

### Phase 2 — Authentication & User Management (Week 3–4)

| Task | Owner |
|---|---|
| Build Login Screen UI | Khadija |
| Implement Firebase Auth login | Sadia |
| Implement role-based routing after login | Sadia |
| Build Admin: Manage Users Screen | Sajida |
| Admin: Create Student/Driver accounts | Sajida |
| Save user to Firestore on creation | Sajida |
| Build Profile Screens (all 3 roles) | Khadija |

**Test:** Admin can create accounts → Student/Driver can log in → Correct screen appears.

---

### Phase 3 — Routes & Schedules (Week 5–6)

| Task | Owner |
|---|---|
| Admin: Add/Edit Route Screen | Sadia |
| Admin: Manage Routes Screen (list, delete) | Sadia |
| Admin: Add/Edit Schedule Screen | Sajida |
| Admin: Manage Schedules Screen | Sajida |
| Admin: Manage Buses Screen | Khadija |
| Student: My Routes Tab (route list) | Khadija |
| Student: Route Detail Screen | Khadija |
| Student: Bus Schedule Screen | Sadia |

**Test:** Admin adds route → Student sees it immediately (real-time).

---

### Phase 4 — Live Tracking (Week 7–8)

| Task | Owner |
|---|---|
| Driver: Start/End Duty Screen | Sadia |
| Driver: GPS location streaming to Firestore | Sadia |
| Student: Live Map Screen (Google Maps) | Khadija |
| Draw route polyline on map | Khadija |
| Real-time driver marker update | Khadija |
| ETA calculation logic | Sajida |
| Handle edge cases (driver offline, no GPS) | All |

**Test:** Driver starts duty → Student sees marker moving on map.

---

### Phase 5 — Notices & Notifications (Week 9)

| Task | Owner |
|---|---|
| Admin: Post Notice Screen | Sajida |
| Admin: Notices List Screen (edit/delete) | Sajida |
| Student/Driver: Notices Tab | Khadija |
| Notice Detail Screen | Khadija |
| FCM token saving on login | Sadia |
| Cloud Function: `onNewNotice` sends FCM | Sadia |
| Flutter: Handle FCM foreground/background | Sadia |

**Test:** Admin posts notice → Students receive push notification instantly.

---

### Phase 6 — Polish, Feedback & Testing (Week 10–11)

| Task | Owner |
|---|---|
| Feedback Screen (student) | Khadija |
| Save feedback to Firestore | Sadia |
| Admin can view feedback | Sajida |
| Onboarding Screens (3 slides) | Khadija |
| Splash Screen | Sadia |
| UI polish (colors, spacing, fonts) | Khadija |
| Handle no-internet state | All |
| Handle empty states (no routes, no notices) | All |
| Beta testing with 10–15 real students | All |
| Bug fixes from feedback | All |

---

### Phase 7 — Final Submission (Week 12)

| Task | Owner |
|---|---|
| Complete system testing (all roles) | All |
| Write project documentation | All |
| Record demo video | Sajida |
| Prepare FYP presentation slides | Khadija |
| Final GitHub push (clean code + README) | Sadia |
| Submit documentation to supervisor | All |

---

## 8. Folder Structure

```
sutms/
├── android/
├── ios/
├── lib/
│   ├── main.dart                    ← App entry point, Firebase init
│   ├── firebase_options.dart        ← Auto-generated by FlutterFire CLI
│   │
│   ├── config/
│   │   ├── app_router.dart          ← GoRouter route definitions
│   │   ├── app_theme.dart           ← Colors, fonts, text styles
│   │   └── constants.dart           ← University ID, app name, etc.
│   │
│   ├── models/                      ← Plain Dart data classes
│   │   ├── user_model.dart
│   │   ├── route_model.dart
│   │   ├── bus_model.dart
│   │   ├── schedule_model.dart
│   │   ├── notice_model.dart
│   │   └── live_location_model.dart
│   │
│   ├── services/                    ← Firebase logic, no UI here
│   │   ├── auth_service.dart        ← Login, logout, role check
│   │   ├── firestore_service.dart   ← All Firestore CRUD operations
│   │   ├── location_service.dart    ← GPS streaming (driver)
│   │   ├── notification_service.dart← FCM token, local notifications
│   │   └── maps_service.dart        ← ETA calculation, polylines
│   │
│   ├── providers/                   ← State management (Provider)
│   │   ├── auth_provider.dart
│   │   ├── route_provider.dart
│   │   ├── notice_provider.dart
│   │   └── location_provider.dart
│   │
│   ├── screens/
│   │   ├── shared/
│   │   │   ├── splash_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   └── login_screen.dart
│   │   │
│   │   ├── student/
│   │   │   ├── student_home_screen.dart
│   │   │   ├── route_list_screen.dart
│   │   │   ├── route_detail_screen.dart
│   │   │   ├── schedule_screen.dart
│   │   │   ├── live_map_screen.dart
│   │   │   ├── notices_screen.dart
│   │   │   ├── notice_detail_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── feedback_screen.dart
│   │   │
│   │   ├── driver/
│   │   │   ├── driver_dashboard.dart
│   │   │   ├── driver_route_screen.dart
│   │   │   ├── duty_toggle_screen.dart
│   │   │   └── driver_profile_screen.dart
│   │   │
│   │   └── admin/
│   │       ├── admin_dashboard.dart
│   │       ├── manage_routes_screen.dart
│   │       ├── add_edit_route_screen.dart
│   │       ├── manage_schedules_screen.dart
│   │       ├── add_edit_schedule_screen.dart
│   │       ├── manage_users_screen.dart
│   │       ├── manage_buses_screen.dart
│   │       ├── post_notice_screen.dart
│   │       ├── notices_list_screen.dart
│   │       └── admin_profile_screen.dart
│   │
│   └── widgets/                     ← Reusable UI components
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       ├── route_card.dart
│       ├── notice_card.dart
│       ├── schedule_table.dart
│       ├── loading_spinner.dart
│       └── empty_state_widget.dart
│
├── functions/                       ← Firebase Cloud Functions
│   ├── index.js                     ← All Cloud Functions
│   └── package.json
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── bus_icon.png
│   │   └── onboarding_1.png ...
│   └── fonts/
│
├── pubspec.yaml
├── README.md
└── .gitignore
```

---

## 9. API Endpoints Reference

> Since this app uses Firebase directly (no custom REST API), the "endpoints" are Firestore collection paths and Firebase Auth methods.

| Operation | Firestore Path / Auth Call |
|---|---|
| Login | `FirebaseAuth.signInWithEmailAndPassword()` |
| Logout | `FirebaseAuth.signOut()` |
| Get current user | `FirebaseAuth.currentUser` → then `users/{uid}` |
| Create user (admin) | `FirebaseAuth.createUserWithEmailAndPassword()` + `users/{uid}` set |
| Get all routes | `routes` where `universityId == X` and `isActive == true` |
| Get route by ID | `routes/{routeId}` |
| Add route | `routes` add document |
| Update route | `routes/{routeId}` update |
| Delete route | `routes/{routeId}` delete (or set `isActive: false`) |
| Get schedules for route | `schedules` where `routeId == X` and `isActive == true` |
| Add schedule | `schedules` add document |
| Get all notices | `notices` where `universityId == X` orderBy `createdAt` desc |
| Add notice | `notices` add document |
| Update notice | `notices/{noticeId}` update |
| Delete notice | `notices/{noticeId}` delete |
| Get driver live location | `liveLocations/{driverId}` snapshots() stream |
| Update driver location | `liveLocations/{driverId}` set (merge: true) |
| Submit feedback | `feedback` add document |
| Save FCM token | `users/{uid}` update `fcmToken` |

---

## 10. Testing Plan

### 10.1 Unit Tests
- Test route model parsing from Firestore snapshot
- Test ETA calculation function
- Test schedule filtering by day of week

### 10.2 Widget Tests
- Test that Login Screen shows error on wrong credentials
- Test that Route Card renders correctly with sample data

### 10.3 Integration / Manual Tests

| Test Case | Expected Result | Role Tested |
|---|---|---|
| Login with correct credentials | Navigate to correct dashboard | All |
| Login with wrong password | Show error SnackBar | All |
| Admin adds a route | Route appears in student route list | Admin + Student |
| Admin adds a schedule | Schedule appears on student schedule screen | Admin + Student |
| Admin posts a notice | Notice appears in notices tab + push notification received | Admin + Student |
| Driver starts duty | Bus marker appears on student's live map | Driver + Student |
| Driver moves | Marker moves on map in ~5 seconds | Driver + Student |
| Driver ends duty | Marker disappears from map | Driver + Student |
| Student submits feedback | Feedback saved to Firestore | Student |
| No internet connection | App shows "No connection" message gracefully | All |
| Multiple universities | University A data not visible to University B users | Admin |

### 10.4 Beta Testing
- Recruit 10–15 students from UoG
- Give them student accounts
- Have 1–2 driver volunteers test the driver app
- Collect feedback via the in-app Feedback Screen
- Fix issues, re-test

---

## 11. Deployment Plan

### 11.1 Firebase Project Setup
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project: `sutms-uog`
3. Enable: Authentication, Firestore, Storage, Cloud Messaging, Functions
4. Download `google-services.json` → place in `android/app/`
5. Download `GoogleService-Info.plist` → place in `ios/Runner/`
6. Run `flutterfire configure` to generate `firebase_options.dart`

### 11.2 Android APK Build (for testing/submission)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 11.3 Firestore Indexes
Create composite indexes in Firebase Console for:
- `routes` — `universityId ASC, isActive ASC, createdAt DESC`
- `notices` — `universityId ASC, isActive ASC, createdAt DESC`
- `schedules` — `routeId ASC, isActive ASC, direction ASC`

### 11.4 Firestore Security Rules (deploy)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can read their own document
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if false; // Only Cloud Functions or admin SDK
    }

    // Routes readable by authenticated users of same university
    match /routes/{routeId} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Notices readable by all authenticated, writable only by admin
    match /notices/{noticeId} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Live location writable only by the driver themselves
    match /liveLocations/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == driverId;
    }

    // Feedback writable by students
    match /feedback/{feedbackId} {
      allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow create: if request.auth != null;
    }
  }
}
```

---

## 12. Risk & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| GPS inaccurate indoors | Medium | Medium | Show last known location + "GPS weak" indicator |
| Firebase free tier quota exceeded | Low | High | Monitor usage in Firebase console; free tier is 50K reads/day which is sufficient for a pilot |
| Student unfamiliar with app | Medium | Low | Include onboarding screens + help section |
| Team member unavailable | Low | High | All code pushed to GitHub daily; tasks documented on Trello |
| Driver forgets to start duty | Medium | Medium | Morning reminder notification sent automatically via scheduled Cloud Function |
| Poor internet at university | Medium | High | Cache last fetched routes/schedules in local storage using `shared_preferences` |
| Google Maps API billing | Low | Medium | Set daily quota limit in Google Cloud Console; free $200/month credit covers well |
| Scope creep | Medium | High | Stick to features listed in proposal; document any additions and discuss with supervisor first |

---

## Summary — What Each Team Member Owns

| Area | Primary Owner | Support |
|---|---|---|
| UI/UX Design & Screens | Khadija | All |
| Firebase Auth & Backend Logic | Sadia | Sajida |
| Admin Panel Screens | Sajida | Sadia |
| Live Tracking Feature | Khadija + Sadia | All |
| Notifications (FCM + Cloud Functions) | Sadia | Sajida |
| Documentation & Report | Sajida | All |
| Testing & QA | All | — |
| Presentation & Demo | Khadija | All |

---

*Document prepared for FYP Spring 2026 — University of Gwadar*  
*Last updated: April 2026*
