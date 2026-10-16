import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class UniversityStudentRecord {
  final String regNumber;
  final String rollNo;
  final String name;
  final String department;
  final String semester;
  final String enrollmentStatus; // Active, Left, Graduated

  UniversityStudentRecord({
    required this.regNumber,
    required this.rollNo,
    required this.name,
    required this.department,
    required this.semester,
    required this.enrollmentStatus,
  });

  factory UniversityStudentRecord.fromMap(Map<String, dynamic> map) {
    return UniversityStudentRecord(
      regNumber: (map['regNumber'] ?? map['registrationNo'] ?? '').toString(),
      rollNo: (map['rollNo'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      department: (map['department'] ?? '').toString(),
      semester: (map['semester'] ?? '').toString(),
      enrollmentStatus: (map['enrollmentStatus'] ?? 'Active').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final rollKey = UniversityDBService.normalizeRollNo(rollNo);
    final regKey = UniversityDBService.normalizeRegNo(regNumber);
    return {
      'rollNo': rollNo.trim(),
      'rollNoKey': rollKey,
      'regNumber': regNumber.trim(),
      'regNumberKey': regKey,
      'name': name.trim(),
      'department': department.trim(),
      'semester': semester.trim(),
      'enrollmentStatus': enrollmentStatus.trim(),
    };
  }
}

/// Thrown when Firestore/network fails — must NOT be treated as "roll not found".
class OfficialLookupException implements Exception {
  final String message;
  OfficialLookupException(this.message);

  @override
  String toString() => message;
}

/// Official university records live in Firestore collection `officialStudents`.
/// Field checked for roll: `rollNoKey` (normalized string — never int).
class UniversityDBService {
  static const String collection = 'officialStudents';

  static FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  /// Trim, strip invisible/zero-width chars, uppercase. Keep leading zeros.
  static String normalizeRollNo(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
    s = s.replaceAll(RegExp(r'\s+'), '');
    return s.toUpperCase();
  }

  static String normalizeRegNo(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
    s = s.replaceAll(RegExp(r'\s+'), '');
    return s.toUpperCase();
  }

  static Future<UniversityStudentRecord?> lookupRecord(String rollNo) async {
    final key = normalizeRollNo(rollNo);
    if (key.isEmpty) return null;

    final db = _db;
    if (db == null) {
      throw OfficialLookupException(
        'Cannot reach university records. Check your internet connection and try again.',
      );
    }

    try {
      final snap = await db
          .collection(collection)
          .where('rollNoKey', isEqualTo: key)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 12));

      if (snap.docs.isEmpty) return null;
      return UniversityStudentRecord.fromMap(snap.docs.first.data());
    } on OfficialLookupException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('officialStudents lookup FirebaseException: ${e.code} ${e.message}');
      throw OfficialLookupException(
        'Cannot reach university records (${e.code}). Check your internet and try again.',
      );
    } catch (e) {
      debugPrint('officialStudents lookup failed: $e');
      throw OfficialLookupException(
        'Cannot reach university records. Check your internet connection and try again.',
      );
    }
  }

  static Future<UniversityStudentRecord?> lookupRecordByReg(String regNumber) async {
    final key = normalizeRegNo(regNumber);
    if (key.isEmpty) return null;

    final db = _db;
    if (db == null) {
      throw OfficialLookupException(
        'Cannot reach university records. Check your internet connection and try again.',
      );
    }

    try {
      final snap = await db
          .collection(collection)
          .where('regNumberKey', isEqualTo: key)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 12));

      if (snap.docs.isEmpty) return null;
      return UniversityStudentRecord.fromMap(snap.docs.first.data());
    } on OfficialLookupException {
      rethrow;
    } on FirebaseException catch (e) {
      throw OfficialLookupException(
        'Cannot reach university records (${e.code}). Check your internet and try again.',
      );
    } catch (e) {
      throw OfficialLookupException(
        'Cannot reach university records. Check your internet connection and try again.',
      );
    }
  }

  /// Primary: roll number. Secondary (optional): registration number.
  static Future<UniversityStudentRecord?> findOfficialMatch({
    required String rollNo,
    String? registrationNo,
  }) async {
    final byRoll = await lookupRecord(rollNo);
    final reg = registrationNo?.trim() ?? '';

    if (byRoll != null) {
      if (reg.isNotEmpty) {
        final regKey = normalizeRegNo(reg);
        final recordReg = normalizeRegNo(byRoll.regNumber);
        if (recordReg.isNotEmpty && recordReg != regKey) {
          // Roll matched but optional reg conflicts — still accept roll match
          // only if regs are empty on either side; otherwise prefer roll.
          debugPrint(
            'Reg mismatch for roll $rollNo: entered=$regKey official=$recordReg (using roll match)',
          );
        }
      }
      return byRoll;
    }

    if (reg.isNotEmpty) {
      return lookupRecordByReg(reg);
    }
    return null;
  }

  /// Seeds / refreshes sample official student records (includes roll "088").
  static Future<void> seedOfficialRecords() async {
    final db = _db;
    if (db == null) return;

    final samples = <UniversityStudentRecord>[
      UniversityStudentRecord(
        regNumber: '5674',
        rollNo: '088',
        name: 'Test Student',
        department: 'Computer Science',
        semester: '4',
        enrollmentStatus: 'Active',
      ),
      UniversityStudentRecord(
        regNumber: 'UOG-2022-123',
        rollNo: '220101',
        name: 'Sajida Abdullah',
        department: 'Computer Science',
        semester: '5',
        enrollmentStatus: 'Active',
      ),
      UniversityStudentRecord(
        regNumber: 'UOG-2022-456',
        rollNo: '220145',
        name: 'Zubair Ahmed',
        department: 'Business Administration',
        semester: '3',
        enrollmentStatus: 'Active',
      ),
      UniversityStudentRecord(
        regNumber: 'UOG-2024-002',
        rollNo: '01234',
        name: 'Khadija Maqbool',
        department: 'Computer Science',
        semester: '1',
        enrollmentStatus: 'Active',
      ),
      UniversityStudentRecord(
        regNumber: 'UOG-2021-789',
        rollNo: '210201',
        name: 'Fatima Zahra',
        department: 'Economics',
        semester: '7',
        enrollmentStatus: 'Graduated',
      ),
      UniversityStudentRecord(
        regNumber: 'UOG-2023-001',
        rollNo: '230101',
        name: 'Zeeshan Khan',
        department: 'Education',
        semester: '1',
        enrollmentStatus: 'Left',
      ),
    ];

    final batch = db.batch();
    for (final record in samples) {
      final id = normalizeRollNo(record.rollNo);
      batch.set(
        db.collection(collection).doc(id),
        record.toMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit().timeout(const Duration(seconds: 20));
    debugPrint('✅ Seeded ${samples.length} officialStudents (incl. roll 088)');
  }
}
