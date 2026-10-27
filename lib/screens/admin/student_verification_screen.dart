import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';
import '../../core/constants/app_colors.dart';
import '../../services/university_db_service.dart';
import '../../widgets/list_skeleton.dart';
import '../../utils/perf_log.dart';

class StudentVerificationScreen extends StatefulWidget {
  const StudentVerificationScreen({super.key});

  @override
  State<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {
  late final Stream<List<StudentModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<StudentProvider>().streamPendingStudents();
    PerfLog.start('screen_StudentVerification');
  }

  Future<void> _quickAction(
    BuildContext context,
    StudentModel student,
    String status,
  ) async {
    try {
      await context.read<StudentProvider>().verifyStudent(student.uid, status);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? '${student.name} approved'
                : '${student.name} rejected',
          ),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.read<StudentProvider>();
    final initial = studentProvider.cachedPending.isEmpty
        ? null
        : studentProvider.cachedPending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Verification'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh official records seed',
            onPressed: () async {
              try {
                await UniversityDBService.seedOfficialRecords();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Official records refreshed (incl. roll 088)'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seed failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.cloud_upload_outlined),
          ),
        ],
      ),
      body: CachedStreamList<List<StudentModel>>(
        stream: _stream,
        initialData: initial,
        emptyMessage: 'No pending verification requests',
        isEmpty: (list) => list.isEmpty,
        onRefresh: () => studentProvider.refreshPending(),
        builder: (context, pendingStudents) {
          PerfLog.end('screen_StudentVerification',
              label: 'first_data', count: pendingStudents.length);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: pendingStudents.length,
            itemBuilder: (context, index) {
              final student = pendingStudents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Roll No: ${student.rollNo}'),
                            Text(
                              'Reg No: ${student.regNumber.isEmpty ? "N/A" : student.regNumber}',
                            ),
                            Text('Dept: ${student.department}'),
                          ],
                        ),
                        trailing: TextButton(
                          onPressed: () => context.push(
                            '/verify-details',
                            extra: student,
                          ),
                          child: const Text('Details'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _quickAction(context, student, 'rejected'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _quickAction(context, student, 'approved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}