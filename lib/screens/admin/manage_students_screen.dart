import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/student_card.dart';
import '../../widgets/list_skeleton.dart';
import '../../models/student_model.dart';
import '../../utils/perf_log.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<StudentModel>> _stream;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _stream = context.read<StudentProvider>().streamStudents();
    PerfLog.start('screen_ManageStudents');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = val.trim().toLowerCase());
    });
  }

  List<StudentModel> _filter(List<StudentModel> all) {
    if (_searchQuery.isEmpty) return all;
    return all
        .where(
          (s) =>
              s.name.toLowerCase().contains(_searchQuery) ||
              s.regNumber.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.read<StudentProvider>();
    final initial = studentProvider.cachedStudents.isEmpty
        ? null
        : studentProvider.cachedStudents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or Reg No...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: CachedStreamList<List<StudentModel>>(
        stream: _stream,
        initialData: initial,
        emptyMessage: 'No students found.',
        isEmpty: (list) => _filter(list).isEmpty,
        onRefresh: () => studentProvider.refreshStudents(),
        builder: (context, data) {
          PerfLog.end('screen_ManageStudents',
              label: 'first_data', count: data.length);
          final students = _filter(data);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return StudentCard(
                student: student,
                onView: () => context.push('/student-details', extra: student),
                onEdit: () =>
                    context.push('/add-edit-student', extra: student),
                onDelete: () =>
                    _confirmDelete(context, student.uid, student.name),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text(
          'Are you sure you want to delete this student? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<StudentProvider>().deleteStudent(uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
