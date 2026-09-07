class UniversityStudentRecord {
  final String regNumber;
  final String name;
  final String department;
  final String semester;
  final String enrollmentStatus; // Active, Left, Graduated

  UniversityStudentRecord({
    required this.regNumber,
    required this.name,
    required this.department,
    required this.semester,
    required this.enrollmentStatus,
  });
}

class UniversityDBService {
  static final List<UniversityStudentRecord> _officialRecords = [
    UniversityStudentRecord(
      regNumber: 'UOG-2022-123',
      name: 'Sajida Abdullah',
      department: 'Computer Science',
      semester: '5',
      enrollmentStatus: 'Active',
    ),
    UniversityStudentRecord(
      regNumber: 'UOG-2022-456',
      name: 'Ali Ahmed',
      department: 'Software Engineering',
      semester: '3',
      enrollmentStatus: 'Active',
    ),
    UniversityStudentRecord(
      regNumber: 'UOG-2021-789',
      name: 'Fatima Zahra',
      department: 'Information Technology',
      semester: '7',
      enrollmentStatus: 'Graduated',
    ),
    UniversityStudentRecord(
      regNumber: 'UOG-2023-001',
      name: 'Zeeshan Khan',
      department: 'Computer Science',
      semester: '1',
      enrollmentStatus: 'Left',
    ),
    UniversityStudentRecord(
      regNumber: 'UOG-2022-999',
      name: 'Mismatched Student',
      department: 'Business Administration',
      semester: '4',
      enrollmentStatus: 'Active',
    ),
    UniversityStudentRecord(
      regNumber: 'UOG-2020-111',
      name: 'Graduated Student',
      department: 'Economics',
      semester: '8',
      enrollmentStatus: 'Graduated',
    ),
  ];

  static UniversityStudentRecord? lookupRecord(String regNumber) {
    try {
      return _officialRecords.firstWhere(
        (record) => record.regNumber.toUpperCase() == regNumber.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
