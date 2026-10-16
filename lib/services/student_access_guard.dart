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
  static Future<StudentAccessResult> evaluate({
    required StudentProvider studentProvider,
    required String uid,
  }) async {
    var student = await studentProvider.getStudent(uid);

    if (student == null) {
      return const StudentAccessResult.denied(
        'No student account found. Please register first.',
      );
    }

    if (student.verificationStatus == 'rejected') {
      return const StudentAccessResult.denied(
        'Your registration was rejected by Admin. Contact the transport office.',
      );
    }

    if (student.verificationStatus == 'approved') {
      return StudentAccessResult.allowed(student);
    }

    // pending — try official records (network errors must not look like "not found")
    UniversityStudentRecord? officialRecord;
    try {
      officialRecord = await UniversityDBService.findOfficialMatch(
        rollNo: student.rollNo,
        registrationNo: student.regNumber,
      );
    } on OfficialLookupException catch (e) {
      return StudentAccessResult.denied(e.message);
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
        fatherName: student.fatherName,
        gender: student.gender,
        dob: student.dob,
        department: student.department.isNotEmpty
            ? student.department
            : officialRecord.department,
        semester: student.semester.isNotEmpty
            ? student.semester
            : officialRecord.semester,
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
