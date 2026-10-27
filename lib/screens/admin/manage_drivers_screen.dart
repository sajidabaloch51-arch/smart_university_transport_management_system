import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/driver_card.dart';
import '../../widgets/list_skeleton.dart';
import '../../models/driver_model.dart';
import '../../utils/perf_log.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<DriverModel>> _stream;
  String _searchQuery = '';
  String _statusFilter = 'All';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DriverProvider>();
    _stream = provider.streamDrivers();
    PerfLog.start('screen_ManageDrivers');
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

  List<DriverModel> _filter(List<DriverModel> all) {
    return all.where((d) {
      final matchesSearch = _searchQuery.isEmpty ||
          d.name.toLowerCase().contains(_searchQuery) ||
          d.driverId.toLowerCase().contains(_searchQuery);
      final matchesStatus =
          _statusFilter == 'All' || d.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.read<DriverProvider>();
    final initial = driverProvider.cachedDrivers.isEmpty
        ? null
        : driverProvider.cachedDrivers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: ['All', 'Active', 'Inactive', 'On Leave']
                      .map((status) {
                    final isSelected = _statusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _statusFilter = status),
                        selectedColor: Colors.green.shade100,
                        checkmarkColor: Colors.green,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CachedStreamList<List<DriverModel>>(
        stream: _stream,
        initialData: initial,
        perfKey: 'screen_ManageDrivers',
        emptyMessage: 'No drivers found.',
        isEmpty: (list) => _filter(list).isEmpty,
        onRefresh: () => driverProvider.refreshDrivers(),
        builder: (context, data) {
          PerfLog.end('screen_ManageDrivers',
              label: 'first_data', count: data.length);
          final drivers = _filter(data);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return DriverCard(
                driver: driver,
                onEdit: () =>
                    context.push('/add-edit-driver', extra: driver),
                onDelete: () =>
                    _confirmDelete(context, driver.uid, driver.name),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-edit-driver'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Driver'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text(
          'Are you sure you want to delete driver $name? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<DriverProvider>().deleteDriver(uid);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
