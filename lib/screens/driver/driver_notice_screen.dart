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
          appBar: AppBar(title: const Text('Official Notices')),
          body: provider.notices.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.notices.length,
                  itemBuilder: (context, index) {
                    final notice = provider.notices[index];
                    return NoticeCard(
                      notice: notice, 
                      onReadMore: () => _showDetails(context, notice),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No new notices found.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, dynamic notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(notice.title),
        content: Text(notice.description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('GOT IT')),
        ],
      ),
    );
  }
}
