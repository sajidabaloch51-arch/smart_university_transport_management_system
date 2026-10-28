import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/feedback_categories.dart';
import '../../models/feedback_model.dart';
import '../../services/feedback_service.dart';
import '../../utils/karachi_time.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackService = FeedbackService();
  late Stream<List<FeedbackModel>> _feedbackStream;

  String _statusFilter = 'all';
  String _categoryFilter = 'all';
  Timer? _waitTimer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _feedbackStream = _feedbackService.streamAllFeedback();
    _armWaitTimeout();
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  void _armWaitTimeout() {
    _waitTimer?.cancel();
    _timedOut = false;
    _waitTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  void _retryStream() {
    _feedbackService.restartStreams();
    setState(() {
      _feedbackStream = _feedbackService.streamAllFeedback();
      _timedOut = false;
    });
    _armWaitTimeout();
  }

  Future<void> _migrate() async {
    try {
      final n = await _feedbackService.migrateLegacyFeedback();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration finished. Updated $n document(s).'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Feedback migration failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _friendlyError(Object e) {
    if (e is FirebaseException) {
      return e.message ?? 'Firebase error (${e.code})';
    }
    return e.toString();
  }

  List<FeedbackModel> _applyFilters(List<FeedbackModel> all) {
    return all.where((f) {
      final statusOk =
          _statusFilter == 'all' || f.status == _statusFilter;
      final categoryOk =
          _categoryFilter == 'all' || f.category == _categoryFilter;
      return statusOk && categoryOk;
    }).toList();
  }

  Future<void> _setStatus(FeedbackModel item, String status) async {
    try {
      await _feedbackService.updateStatus(item.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as ${FeedbackStatuses.label(status)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('updateStatus failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e)), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmDelete(FeedbackModel item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete feedback'),
        content: const Text('Permanently delete this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _feedbackService.deleteFeedback(item.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feedback deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                debugPrint('deleteFeedback failed: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_friendlyError(e)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openDetail(FeedbackModel item) {
    final noteController = TextEditingController(text: item.adminNote ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(item.message),
                const SizedBox(height: 16),
                Text(
                  'Submitted: ${KarachiTime.formatDateTime(item.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  'Student: ${item.studentName?.isNotEmpty == true ? item.studentName : 'Hidden until needed'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (item.rollNo != null && item.rollNo!.isNotEmpty)
                  Text('Roll No: ${item.rollNo}'),
                if (item.department != null && item.department!.isNotEmpty)
                  Text('Department: ${item.department}'),
                Text(
                  'Account id: ${item.studentUid.isEmpty ? '—' : item.studentUid}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Admin reply / note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        await _feedbackService.updateStatus(
                          item.id,
                          FeedbackStatuses.reviewed,
                          adminNote: noteController.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Mark Reviewed'),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        await _feedbackService.updateStatus(
                          item.id,
                          FeedbackStatuses.resolved,
                          adminNote: noteController.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Mark Resolved'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await _feedbackService.updateStatus(
                          item.id,
                          item.status,
                          adminNote: noteController.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save note'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Feedback'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'migrate') _migrate();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'migrate',
                child: Text('Migrate legacy feedback (one-time)'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<FeedbackModel>>(
        stream: _feedbackStream,
        builder: (context, snapshot) {
          if (snapshot.hasData || snapshot.hasError) {
            _waitTimer?.cancel();
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData &&
              !snapshot.hasError) {
            if (_timedOut) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Can't reach the server. Check your connection",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _retryStream,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Column(
              children: [
                LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ],
            );
          }
          if (snapshot.hasError) {
            final err = snapshot.error!;
            debugPrint('Admin feedback stream error: $err');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _friendlyError(err),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retryStream,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final all = snapshot.data ?? const <FeedbackModel>[];
          final newCount =
              all.where((f) => f.status == FeedbackStatuses.newStatus).length;
          final filtered = _applyFilters(all);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'New',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: newCount > 0
                          ? Colors.orange
                          : Colors.grey.shade300,
                      child: Text(
                        '$newCount',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    _statusChip('all', 'All'),
                    _statusChip(FeedbackStatuses.newStatus, 'New'),
                    _statusChip(FeedbackStatuses.reviewed, 'Reviewed'),
                    _statusChip(FeedbackStatuses.resolved, 'Resolved'),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    _categoryChip('all', 'All categories'),
                    ...FeedbackCategories.all.map(
                      (c) => _categoryChip(c, c),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: all.isEmpty
                    ? const Center(
                        child: Text(
                          'No feedback submitted yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No feedback matches these filters.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              return _FeedbackAdminCard(
                                item: filtered[index],
                                onOpen: () => _openDetail(filtered[index]),
                                onReviewed: () => _setStatus(
                                  filtered[index],
                                  FeedbackStatuses.reviewed,
                                ),
                                onResolved: () => _setStatus(
                                  filtered[index],
                                  FeedbackStatuses.resolved,
                                ),
                                onDelete: () =>
                                    _confirmDelete(filtered[index]),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = value),
      ),
    );
  }

  Widget _categoryChip(String value, String label) {
    final selected = _categoryFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _categoryFilter = value),
      ),
    );
  }
}

class _FeedbackAdminCard extends StatelessWidget {
  final FeedbackModel item;
  final VoidCallback onOpen;
  final VoidCallback onReviewed;
  final VoidCallback onResolved;
  final VoidCallback onDelete;

  const _FeedbackAdminCard({
    required this.item,
    required this.onOpen,
    required this.onReviewed,
    required this.onResolved,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = FeedbackCategories.colorFor(item.category);
    final statusColor = FeedbackStatuses.colorFor(item.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FeedbackCategories.iconFor(item.category),
                          size: 14,
                          color: catColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.category,
                          style: TextStyle(
                            color: catColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      FeedbackStatuses.label(item.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                KarachiTime.formatDateTime(item.createdAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                item.department?.isNotEmpty == true
                    ? 'Anonymous student · ${item.department}'
                    : 'Anonymous student',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Note: ${item.adminNote}',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: onReviewed,
                    child: const Text('Reviewed'),
                  ),
                  TextButton(
                    onPressed: onResolved,
                    child: const Text('Resolved'),
                  ),
                  TextButton(
                    onPressed: onDelete,
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
