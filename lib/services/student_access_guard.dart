import 'package:flutter/foundation.dart';

import '../models/student_model.dart';
import '../providers/student_provider.dart';
import 'university_db_service.dart';

/// Result of checking whether a student may enter the app.
class StudentAccessResult {
  final bool allowed;
  final String? message;
  final StudentModel? student;

  const StudentAccessResult.allowed(this.student)
      : allowed = true,
        message = null;

  const StudentAccessResult.denied(this.message)
      : allowed = false,
        student = null;
}

class StudentAccessGuard {
  /// Students may enter only when verificationStatus is `approved`.
  /// Pending students who appear in official Active records are auto-approved.
  ///
  /// Always reads a fresh Firestore server copy — a stale local cache that
  /// still says `pending` after Admin approval was blocking login and then
  /// wasting ~12s on officialStudents lookup.
  static Future<StudentAccessResult> evaluate({
    required StudentProvider studentProvider,
    required String uid,
  }) async {
    final student = await studentProvider.getStudentFresh(uid);

    if (student == null) {
      debugPrint('StudentAccessGuard: no user doc for uid=$uid');
      return const StudentAccessResult.denied(
        'No student account found. Please register first.',
      );
    }

    final status = student.verificationStatus.trim().toLowerCase();
    debugPrint(
      'StudentAccessGuard uid=$uid status=$status roll=${student.rollNo}',
    );

    if (status == 'rejected') {
      return const StudentAccessResult.denied(
        'Your registration was rejected by Admin. Contact the transport office.',
      );
    }

    if (status == 'approved') {
      return StudentAccessResult.allowed(student);
    }

    // Still pending on server — try official records (bounded timeout).
    UniversityStudentRecord? officialRecord;
    try {
      officialRecord = await UniversityDBService.findOfficialMatch(
        rollNo: student.rollNo,
        registrationNo: student.regNumber,
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          debugPrint('StudentAccessGuard: official lookup timed out');
          return null;
        },
      );
    } on OfficialLookupException catch (e) {
      // Network failure must not override a real approval (already handled).
      // For pending, tell the user we could not re-check records.
      return StudentAccessResult.denied(
        '${e.message} If an administrator already approved you, pull to refresh '
        'or try again on a stable connection.',
      );
    }

    if (officialRecord != null &&
        officialRecord.enrollmentStatus == 'Active') {
      final approved = StudentModel(
        uid: student.uid,
        name: student.name,
        email: student.email,
        phone: student.phone,
        role: student.role,
        regNumber: student.regNumber.isNotEmpty
            ? student.regNumber
            : officialRecord.regNumber,
        department: student.department.isNotEmpty
            ? student.department
            : officialRecord.department,
        profileImage: student.profileImage,
        routeAddress: student.routeAddress,
        rollNo: student.rollNo,
        assignedRouteId: student.assignedRouteId,
        assignedRouteName: student.assignedRouteName,
        assignedBusId: student.assignedBusId,
        assignedBusName: student.assignedBusName,
        assignedBusCode: student.assignedBusCode,
        assignedDriverId: student.assignedDriverId,
        assignedDriverName: student.assignedDriverName,
        assignedDriverPhone: student.assignedDriverPhone,
        assignedDepartureTime: student.assignedDepartureTime,
        assignedArrivalTime: student.assignedArrivalTime,
        verificationStatus: 'approved',
        passwordHash: student.passwordHash,
        termsAccepted: student.termsAccepted,
        termsVersion: student.termsVersion,
      );
      await studentProvider.updateStudent(approved);
      return StudentAccessResult.allowed(approved);
    }

    if (officialRecord != null &&
        officialRecord.enrollmentStatus != 'Active') {
      return StudentAccessResult.denied(
        'Your university enrollment status is "${officialRecord.enrollmentStatus}". Access denied.',
      );
    }

    return const StudentAccessResult.denied(
      'Your account is awaiting admin approval. Please wait until an administrator verifies your registration.',
    );
  }
}
