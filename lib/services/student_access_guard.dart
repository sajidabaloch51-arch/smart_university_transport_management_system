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
  /// Students may enter only when:
  /// - they have a registered account, AND
  /// - verificationStatus is `approved`
  ///
  /// Auto-approve happens only if Roll No exists in the university DB
  /// and enrollment status is Active.
  static Future<StudentAccessResult> evaluate({
    required StudentProvider studentProvider,
    required String uid,
  }) async {
    var student = await studentProvider.getStudent(uid);

    if (student == null) {
      return const StudentAccessResult.denied(
        'No student account found. Please register first and wait for verification.',
      );
    }

    if (student.verificationStatus == 'rejected') {
      return const StudentAccessResult.denied(
        'Your registration was rejected by the Admin. Contact transport office.',
      );
    }

    final officialRecord = UniversityDBService.lookupRecord(student.rollNo);

    // Auto-approve only when official Active record exists
    if (student.verificationStatus == 'pending' && officialRecord != null) {
      if (officialRecord.enrollmentStatus != 'Active') {
        return StudentAccessResult.denied(
          'Your university enrollment status is "${officialRecord.enrollmentStatus}". Access denied.',
        );
      }

      final approved = StudentModel(
        uid: student.uid,
        name: student.name,
        email: student.email,
        phone: student.phone,
        role: student.role,
        regNumber: student.regNumber,
        fatherName: student.fatherName,
        gender: student.gender,
        dob: student.dob,
        department: student.department,
        semester: student.semester,
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
      );
      await studentProvider.updateStudent(approved);
      return StudentAccessResult.allowed(approved);
    }

    // No university record → must wait for admin verification
    if (student.verificationStatus != 'approved') {
      if (officialRecord == null) {
        return const StudentAccessResult.denied(
          'Your Roll No was not found in university records. Account is pending Admin verification. You cannot login yet.',
        );
      }
      return const StudentAccessResult.denied(
        'Your account is pending Admin verification. Please wait for approval.',
      );
    }

    return StudentAccessResult.allowed(student);
  }
}
