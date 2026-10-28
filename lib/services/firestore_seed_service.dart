import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/alert_model.dart';
import '../models/bus_model.dart';
import '../models/driver_model.dart';
import '../models/duty_model.dart';
import '../models/notice_model.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';
import '../models/student_model.dart';
import '../constants/demo_credentials.dart';
import '../models/user_model.dart';
import '../utils/karachi_time.dart';
import 'firebase_bootstrap.dart';
import 'password_hasher.dart';
import 'university_db_service.dart';

/// Seeds lean SUTMS data into Firestore (fields the frontend actually uses).
/// Document IDs match login UIDs: `{emailLocalPart}_id`
class FirestoreSeedService {
  static const String seedVersion = 'sutms-uog-v8-route-driver-assignment';

  static const String adminUid = 'admin_id';
  static const String driverUid = 'driver_id';
  static const String studentUid = 'student_id';
  static const String routeId = 'route_campus_city';
  static const String busId = 'bus_01';
  static const String scheduleId = 'schedule_morning_01';
  static const String noticeId = 'notice_welcome_01';

  /// Returns true when seed ran (or already present). False if Firestore missing.
  /// Pass [force] from the Admin "Seed sample data" button to re-write TEST DATA.
  static Future<bool> ensureSeedData({bool force = false}) async {
    final db = FirebaseBootstrap.firestore;
    if (db == null) {
      debugPrint('⚠️ Seed skipped: Firebase not ready');
      return false;
    }

    // Always refresh today's demo duty + broadcast alert (non-blocking).
    // ignore: unawaited_futures
    _ensureDemoDutiesAndAlerts(db);

    try {
      final meta = await db.collection('_meta').doc('seed').get().timeout(
            const Duration(seconds: 3),
          );
      final current = meta.data()?['version'];
      if (!force && current == seedVersion) {
        // Fast path — do not block launch with extra writes.
        // ignore: unawaited_futures
        _ensureApprovedAdmins(db);
        debugPrint('✅ Firestore seed already applied ($seedVersion)');
        return true;
      }

      debugPrint('⏳ Cleaning junk docs + seeding lean Firestore data…');
      await _deleteJunkUsers(db);
      await _cleanBuses(db);
      await UniversityDBService.seedOfficialRecords();

      final batch = db.batch();
      final now = DateTime.now();
      // Always write demo password hashes in the same batch below.

      // Admin — identity + demo password hash (never plaintext)
      final adminMap = UserModel(
        uid: adminUid,
        name: 'Transport Admin',
        email: DemoCredentials.adminEmail,
        phone: '03001234567',
        role: 'admin',
      ).toMap();
      adminMap['passwordHash'] =
          PasswordHasher.hash(DemoCredentials.adminPassword);
      batch.set(db.collection('users').doc(adminUid), adminMap);

      // Driver — lean fields + demo password hash
      final driverMap = DriverModel(
        uid: driverUid,
        name: 'Ahmed Baloch',
        email: DemoCredentials.driverEmail,
        phone: '03007654321',
        role: 'driver',
        driverId: 'DRV-001',
        experienceYears: 5,
        status: 'Active',
        assignedBusId: busId,
        assignedBusNumber: 'UOG-01',
        assignedRouteId: routeId,
        assignedRouteName: 'Campus ↔ City',
        isOnDuty: false,
      ).toMap();
      driverMap['passwordHash'] =
          PasswordHasher.hash(DemoCredentials.driverPassword);
      batch.set(db.collection('users').doc(driverUid), driverMap);

      // Student — lean assignment + demo password hash
      batch.set(
        db.collection('users').doc(studentUid),
        StudentModel(
          uid: studentUid,
          name: 'Sara Khan',
          email: DemoCredentials.studentEmail,
          phone: '03009876543',
          role: 'student',
          regNumber: 'UOG-2024-001',
          department: 'Computer Science',
          rollNo: 'CS-042',
          assignedRouteId: routeId,
          assignedRouteName: 'Campus ↔ City',
          assignedBusId: busId,
          assignedBusCode: 'UOG-01',
          assignedDriverId: driverUid,
          assignedDriverName: 'Ahmed Baloch',
          assignedDriverPhone: '03007654321',
          assignedDepartureTime: '07:30 AM',
          assignedArrivalTime: '08:15 AM',
          verificationStatus: 'approved',
          passwordHash: PasswordHasher.hash(DemoCredentials.studentPassword),
        ).toMap(),
      );

      // Route with map stops + assigned driver (source of truth for students).
      batch.set(
        db.collection('routes').doc(routeId),
        RouteModel(
          id: routeId,
          universityId: 'uog',
          routeName: 'Campus ↔ City',
          routeNumber: 'R-01',
          startLocation: 'UoG Campus',
          endLocation: 'Gwadar City Center',
          viaStops: ['Marine Drive', 'Airport Road'],
          stops: [
            RouteStop(
              stopName: 'UoG Campus',
              lat: 25.1982,
              lng: 62.3254,
              order: 0,
              timeLabel: '07:30 AM',
            ),
            RouteStop(
              stopName: 'Marine Drive',
              lat: 25.1600,
              lng: 62.3400,
              order: 1,
              timeLabel: '07:45 AM',
            ),
            RouteStop(
              stopName: 'Airport Road',
              lat: 25.1400,
              lng: 62.3500,
              order: 2,
              timeLabel: '08:00 AM',
            ),
            RouteStop(
              stopName: 'Gwadar City Center',
              lat: 25.1216,
              lng: 62.3254,
              order: 3,
              timeLabel: '08:15 AM',
            ),
          ],
          distanceKm: '18',
          estimatedTime: '45 min',
          departureTime: '07:30 AM',
          arrivalTime: '08:15 AM',
          driverId: driverUid,
          driverName: 'Ahmed Baloch',
          driverPhone: '03007654321',
          busNo: 'UOG-01',
        ).toMap(),
      );

      batch.set(
        db.collection('driverPublic').doc(driverUid),
        {
          'name': 'Ahmed Baloch',
          'phone': '03007654321',
          'busNo': 'UOG-01',
          'routeId': routeId,
        },
      );

      // Bus
      batch.set(
        db.collection('buses').doc(busId),
        BusModel(
          id: busId,
          busNumber: 'UOG-01',
          registrationNumber: 'GS-2024-01',
          assignedDriverId: driverUid,
          assignedDriverName: 'Ahmed Baloch',
          assignedRouteId: routeId,
          assignedRouteName: 'Campus ↔ City',
        ).toMap(),
      );

      // Schedule
      batch.set(
        db.collection('schedules').doc(scheduleId),
        ScheduleModel(
          id: scheduleId,
          driverId: driverUid,
          driverName: 'Ahmed Baloch',
          routeId: routeId,
          routeName: 'Campus ↔ City',
          date: DateTime(now.year, now.month, now.day),
          departureTime: '07:30 AM',
          arrivalTime: '08:15 AM',
          shift: 'Morning',
          vehicleNo: 'UOG-01',
          status: 'Scheduled',
        ).toMap(),
      );

      // Notice
      batch.set(
        db.collection('notices').doc(noticeId),
        NoticeModel(
          id: noticeId,
          title: 'Welcome to SUTMS',
          description:
              'University of Gwadar transport is online. Check your assigned bus and live tracking.',
          date: now,
          type: NoticeType.general,
          postedBy: 'Transport Admin',
          targetAudience: 'all',
        ).toMap(),
      );

      batch.set(db.collection('_meta').doc('health'), {
        'ok': true,
        'project': 'sutms-uog',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(db.collection('_meta').doc('seed'), {
        'version': seedVersion,
        'seededAt': FieldValue.serverTimestamp(),
        'logins': {
          'admin': DemoCredentials.adminEmail,
          'driver': DemoCredentials.driverEmail,
          'student': DemoCredentials.studentEmail,
        },
        'passwordsHint': {
          'admin': DemoCredentials.adminPassword,
          'driver': DemoCredentials.driverPassword,
          'student': DemoCredentials.studentPassword,
        },
        'schema': 'demo-passwords-v6-admin-allowlist',
      });

      await batch.commit().timeout(const Duration(seconds: 20));
      await _ensureDemoCredentials(db);
      await _ensureApprovedAdmins(db);
      await _ensureDemoDutiesAndAlerts(db);
      debugPrint('✅ Firestore lean seed applied ($seedVersion)');
      debugPrint(
        '🔑 Admin login: ${DemoCredentials.adminEmail} / ${DemoCredentials.adminPassword}',
      );
      return true;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firestore seed failed: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Firestore seed failed: $e');
      return false;
    }
  }

  /// Removes tutorial/junk docs (e.g. Ada Lovelace samples without `role`).
  static Future<void> _deleteJunkUsers(FirebaseFirestore db) async {
    try {
      final snap = await db.collection('users').get().timeout(
            const Duration(seconds: 15),
          );
      final batch = db.batch();
      var count = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final hasRole =
            data['role'] is String && (data['role'] as String).isNotEmpty;
        final looksLikeTutorial = data.containsKey('first') &&
            data.containsKey('last') &&
            data.containsKey('born');
        if (!hasRole || looksLikeTutorial) {
          batch.delete(doc.reference);
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
        debugPrint('🧹 Removed $count junk user document(s)');
      }
    } catch (e) {
      debugPrint('Junk user cleanup skipped: $e');
    }
  }

  /// Only emails in this collection may complete Admin Registration.
  static Future<void> _ensureApprovedAdmins(FirebaseFirestore db) async {
    try {
      final email = DemoCredentials.adminEmail.toLowerCase();
      await db.collection('approvedAdmins').doc(email).set({
        'email': email,
        'name': 'Transport Admin',
        'active': true,
      }, SetOptions(merge: true));
      debugPrint('✅ Approved admin allowlist ready ($email)');
    } catch (e) {
      debugPrint('Approved admins upsert skipped: $e');
    }
  }

  /// Ensures Driver Dashboard has at least one duty today + one broadcast alert.
  static Future<void> _ensureDemoDutiesAndAlerts(FirebaseFirestore db) async {
    try {
      final today = KarachiTime.dateString();
      final start = KarachiTime.combineToUtc(
        DateTime.utc(
          int.parse(today.substring(0, 4)),
          int.parse(today.substring(5, 7)),
          int.parse(today.substring(8, 10)),
        ),
        7,
        30,
      );
      final end = KarachiTime.combineToUtc(
        DateTime.utc(
          int.parse(today.substring(0, 4)),
          int.parse(today.substring(5, 7)),
          int.parse(today.substring(8, 10)),
        ),
        14,
        0,
      );

      final duty = DutyModel(
        id: 'duty_demo_$today',
        driverId: driverUid,
        driverName: 'Ahmed Baloch',
        busNo: 'UOG-01',
        route: 'Campus ↔ City',
        shiftStart: start,
        shiftEnd: end,
        dutyDate: today,
        notes: 'Demo morning shift',
        status: 'scheduled',
        createdBy: adminUid,
        createdAt: DateTime.now().toUtc(),
      );
      await db
          .collection('duties')
          .doc(duty.id)
          .set(duty.toMap(), SetOptions(merge: true));

      final alert = AlertModel(
        id: 'alert_demo_welcome',
        title: 'Transport Desk',
        message:
            'Welcome drivers. Check Today\'s Active Duties for your assigned shift.',
        severity: 'info',
        target: 'all_drivers',
        driverId: null,
        isActive: true,
        createdBy: adminUid,
        createdAt: DateTime.now().toUtc(),
      );
      await db
          .collection('alerts')
          .doc(alert.id)
          .set(alert.toMap(), SetOptions(merge: true));

      debugPrint(
        '✅ Demo duty ($today → $driverUid) + broadcast alert ready',
      );
    } catch (e) {
      debugPrint('Demo duties/alerts upsert skipped: $e');
    }
  }

  /// Upserts demo admin/driver/student password hashes so login works
  /// even when Firebase Auth Email/Password is not enabled.
  static Future<void> _ensureDemoCredentials(FirebaseFirestore db) async {
    try {
      final batch = db.batch();
      batch.set(
        db.collection('users').doc(adminUid),
        {
          'uid': adminUid,
          'name': 'Transport Admin',
          'email': DemoCredentials.adminEmail,
          'phone': '03001234567',
          'role': 'admin',
          'isActive': true,
          'passwordHash':
              PasswordHasher.hash(DemoCredentials.adminPassword),
        },
        SetOptions(merge: true),
      );
      batch.set(
        db.collection('users').doc(driverUid),
        {
          'uid': driverUid,
          'email': DemoCredentials.driverEmail,
          'role': 'driver',
          'passwordHash':
              PasswordHasher.hash(DemoCredentials.driverPassword),
        },
        SetOptions(merge: true),
      );
      batch.set(
        db.collection('users').doc(studentUid),
        {
          'uid': studentUid,
          'email': DemoCredentials.studentEmail,
          'role': 'student',
          'verificationStatus': 'approved',
          'passwordHash':
              PasswordHasher.hash(DemoCredentials.studentPassword),
        },
        SetOptions(merge: true),
      );
      await batch.commit().timeout(const Duration(seconds: 15));
      debugPrint(
        '✅ Demo credentials ready — '
        'admin ${DemoCredentials.adminEmail} / ${DemoCredentials.adminPassword}',
      );
    } catch (e) {
      debugPrint('Demo credentials upsert skipped: $e');
    }
  }

  /// Rewrites every `buses` doc without empty IDs, "Not Assigned", nulls.
  static Future<void> _cleanBuses(FirebaseFirestore db) async {
    try {
      final snap = await db.collection('buses').get().timeout(
            const Duration(seconds: 15),
          );
      final batch = db.batch();
      var cleaned = 0;
      for (final doc in snap.docs) {
        final bus = BusModel.fromMap(doc.data(), doc.id);
        if (bus.busNumber.trim().isEmpty) {
          batch.delete(doc.reference);
          cleaned++;
          continue;
        }
        // Full replace drops assignedDriverId "", capacity null, etc.
        batch.set(doc.reference, bus.toMap());
        cleaned++;
      }
      if (cleaned > 0) {
        await batch.commit();
        debugPrint('🧹 Cleaned $cleaned buses document(s)');
      }
    } catch (e) {
      debugPrint('Buses cleanup skipped: $e');
    }
  }
}
