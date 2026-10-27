import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'live_bus_tracking_screen.dart';
import 'route_screen.dart';
import 'notice_screen.dart';
import 'profile_screen.dart';
import '../../models/notice_model.dart';
import '../../providers/notice_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/notice_card.dart';
import '../../widgets/list_skeleton.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeTab(),
    RouteScreen(),
    LiveBusTrackingScreen(),
    NoticeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus),
            label: 'Routes',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<NoticeModel>> _noticesStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _noticesStream = context.read<NoticeProvider>().streamNotices();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final noticeProvider = context.read<NoticeProvider>();
    final initial = noticeProvider.cachedNotices.isEmpty
        ? null
        : noticeProvider.cachedNotices.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart University', style: TextStyle(fontSize: 18)),
            Text(
              'Transport System',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            onPressed: () => context.push('/personal-info'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Route...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildQuickMenuCard(
                  context,
                  'My Routes',
                  Icons.route,
                  AppColors.primary,
                  '/student-routes',
                ),
                _buildQuickMenuCard(
                  context,
                  'Live Tracking',
                  Icons.map,
                  Colors.green,
                  '/live-tracking',
                ),
                _buildQuickMenuCard(
                  context,
                  'Schedule',
                  Icons.schedule,
                  Colors.orange,
                  '/schedule',
                ),
                _buildQuickMenuCard(
                  context,
                  'Feedback',
                  Icons.feedback,
                  Colors.purple,
                  '/feedback',
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              "Today's Updates",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<NoticeModel>>(
              stream: _noticesStream,
              initialData: initial,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 88, child: ListSkeleton(itemCount: 1));
                }
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return const Text('No new updates for today.');
                }
                final notice = list.first;
                return NoticeCard(
                  notice: notice,
                  onReadMore: () =>
                      context.push('/notice-detail', extra: notice),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return Card(
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
