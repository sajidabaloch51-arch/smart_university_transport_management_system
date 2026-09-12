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
}

class UniversityDBService {
  static final List<UniversityStudentRecord> _officialRecords = [
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

  static UniversityStudentRecord? lookupRecord(String rollNo) {
    try {
      return _officialRecords.firstWhere(
        (record) => record.rollNo.toUpperCase() == rollNo.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static UniversityStudentRecord? lookupRecordByReg(String regNumber) {
    try {
      return _officialRecords.firstWhere(
        (record) => record.regNumber.toUpperCase() == regNumber.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
