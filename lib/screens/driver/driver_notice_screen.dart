import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/notice_card.dart';

class DriverNoticeScreen extends StatelessWidget {
  const DriverNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('University Notices')),
          body: provider.notices.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.notices.length,
                  itemBuilder: (context, index) {
                    return NoticeCard(
                      notice: provider.notices[index],
                      onReadMore: () => _showNoticeDialog(context, provider.notices[index]),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No notices available', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showNoticeDialog(BuildContext context, dynamic notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notice.title),
        content: SingleChildScrollView(
          child: Text(notice.description),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
