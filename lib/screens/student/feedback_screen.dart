import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/feedback_categories.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/feedback_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _feedbackService = FeedbackService();
  String? _selectedCategory;
  bool _isLoading = false;
  int _dropdownResetKey = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'Permission denied. Sign in as a student and try again.';
        case 'unavailable':
        case 'network-request-failed':
          return 'You appear to be offline. Check your connection and try again.';
        default:
          return e.message ?? 'Could not send feedback (${e.code}).';
      }
    }
    return e.toString();
  }

  Future<void> _submitFeedback() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final category = _selectedCategory;
    if (category == null || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a feedback category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authUid = FirebaseAuth.instance.currentUser?.uid ??
        context.read<AuthProvider>().uid;
    if (authUid == null || authUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to send feedback.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final student =
          await context.read<StudentProvider>().getStudent(authUid);

      await _feedbackService.submitFeedback(
        category: category,
        message: _commentController.text,
        studentUid: authUid,
        studentName: student?.name,
        rollNo: student?.rollNo,
        department: student?.department,
      );

      if (!mounted) return;
      _commentController.clear();
      setState(() {
        _selectedCategory = null;
        _isLoading = false;
        _dropdownResetKey++;
      });
      _formKey.currentState?.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you, your feedback was sent'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint('Feedback submit failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Feedback Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('cat-$_dropdownResetKey'),
                decoration: InputDecoration(
                  hintText: 'Choose a category',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                initialValue: _selectedCategory,
                items: FeedbackCategories.all.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (newValue) =>
                        setState(() => _selectedCategory = newValue),
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 28),
              const Text(
                'Your Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _commentController,
                labelText: 'Tell us what we can improve...',
                prefixIcon: Icons.edit_note_rounded,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                maxLength: 1000,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your feedback';
                  }
                  if (value.trim().length < 10) {
                    return 'Message must be at least 10 characters long';
                  }
                  if (value.trim().length > 1000) {
                    return 'Message must be at most 1000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'SEND FEEDBACK',
                isLoading: _isLoading,
                onPressed: _submitFeedback,
              ),
              const SizedBox(height: 20),
              Text(
                'Your feedback is visible only to the Transport Admin. '
                'Other students cannot see it. We store your account id '
                'so Admin can handle abuse; your name is not shown in the '
                'public list.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
