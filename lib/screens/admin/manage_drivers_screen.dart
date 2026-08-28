import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/driver_card.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search driver by name or ID...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<DriverProvider>(
        builder: (context, provider, child) {
          // In a real app, this list would come from a stream or fetched data
          // For now, we simulate the display logic
          final driver = provider.driver;
          if (driver == null) return const Center(child: Text('No drivers found.'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DriverCard(driver: driver),
              // Map additional drivers here
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-driver'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Driver'),
      ),
    );
  }
}
