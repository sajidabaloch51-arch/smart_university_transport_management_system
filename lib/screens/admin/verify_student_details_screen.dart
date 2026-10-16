import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../providers/student_provider.dart';
import '../../services/university_db_service.dart';
import '../../core/constants/app_colors.dart';

class VerifyStudentDetailsScreen extends StatefulWidget {
  final StudentModel student;

  const VerifyStudentDetailsScreen({super.key, required this.student});

  @override
  State<VerifyStudentDetailsScreen> createState() =>
      _VerifyStudentDetailsScreenState();
}

class _VerifyStudentDetailsScreenState
    extends State<VerifyStudentDetailsScreen> {
  UniversityStudentRecord? _officialRecord;
  bool _isChecking = true;
  String? _lookupError;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _checkRecord();
  }

  Future<void> _checkRecord() async {
    setState(() {
      _isChecking = true;
      _lookupError = null;
    });
    try {
      final record = await UniversityDBService.findOfficialMatch(
        rollNo: widget.student.rollNo,
        registrationNo: widget.student.regNumber,
      );
      if (!mounted) return;
      setState(() {
        _officialRecord = record;
        _isChecking = false;
      });
    } on OfficialLookupException catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupError = e.message;
        _isChecking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupError = 'Could not load official records: $e';
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Student Submitted Information'),
                  _buildSubmittedInfoCard(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('University Official Record'),
                  _buildOfficialRecordCard(),
                  const SizedBox(height: 32),
                  _buildVerificationStatus(),
                  const SizedBox(height: 48),
                  _buildActionButtons(context),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSubmittedInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(Icons.person_outline, 'Full Name', widget.student.name),
            const Divider(),
            _infoRow(
              Icons.format_list_numbered,
              'Roll No',
              widget.student.rollNo,
            ),
            const Divider(),
            _infoRow(
              Icons.badge_outlined,
              'Registration Number',
              widget.student.regNumber.isEmpty ? 'N/A' : widget.student.regNumber,
            ),
            const Divider(),
            _infoRow(Icons.phone_outlined, 'Phone Number', widget.student.phone),
            const Divider(),
            _infoRow(
              Icons.school_outlined,
              'Department',
              widget.student.department,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficialRecordCard() {
    if (_lookupError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, color: Colors.orange, size: 40),
            const SizedBox(height: 12),
            Text(
              _lookupError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(onPressed: _checkRecord, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_officialRecord == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 40),
            SizedBox(height: 12),
            Text(
              'No matching record found in the university database. You can still Approve or Reject manually.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(
              Icons.badge,
              'Registration Number',
              _officialRecord!.regNumber,
            ),
            const Divider(),
            _infoRow(Icons.person, 'Student Name', _officialRecord!.name),
            const Divider(),
            _infoRow(Icons.school, 'Department', _officialRecord!.department),
            const Divider(),
            _infoRow(
              Icons.calendar_today,
              'Semester',
              _officialRecord!.semester,
            ),
            const Divider(),
            _infoRow(
              Icons.check_circle_outline,
              'Enrollment Status',
              _officialRecord!.enrollmentStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStatus() {
    if (_lookupError != null) {
      return _statusBanner(
        'Network / lookup issue',
        Colors.orange,
        'Official records could not be loaded. You may still approve or reject manually.',
      );
    }

    if (_officialRecord == null) {
      return _statusBanner(
        'Roll No Not Found',
        Colors.red,
        'The roll number is not in official records. Manual admin decision required.',
      );
    }

    final nameMatch = widget.student.name.toLowerCase().trim() ==
        _officialRecord!.name.toLowerCase().trim();
    if (!nameMatch) {
      return _statusBanner(
        'Information Mismatch — Please Verify',
        Colors.orange,
        'Submitted name does not match the official record. Review carefully before approving.',
      );
    }

    if (_officialRecord!.enrollmentStatus != 'Active') {
      return _statusBanner(
        'Student is Inactive / Has Left University',
        Colors.red,
        'Official status: ${_officialRecord!.enrollmentStatus}.',
      );
    }

    return _statusBanner(
      'Verified — Active Student',
      Colors.green,
      'Submitted information matches an official Active record.',
    );
  }

  Widget _statusBanner(String title, Color color, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Manual verification always allowed for pending students.
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isActing
                ? null
                : () => _handleAction(context, 'rejected'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'REJECT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isActing
                ? null
                : () => _handleAction(context, 'approved'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isActing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'APPROVE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, String status) async {
    setState(() => _isActing = true);
    try {
      final studentProvider =
          Provider.of<StudentProvider>(context, listen: false);
      await studentProvider.verifyStudent(widget.student.uid, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Student approved — they can log in now.'
                : 'Student registration rejected.',
          ),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
