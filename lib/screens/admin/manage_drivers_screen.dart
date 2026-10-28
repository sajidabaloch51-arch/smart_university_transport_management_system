import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/driver_model.dart';
import '../../providers/driver_provider.dart';
import '../../services/route_assignment_service.dart';
import '../../utils/perf_log.dart';
import '../../widgets/driver_card.dart';
import '../../widgets/list_skeleton.dart';

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
  bool _repairing = false;

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

  bool _isUnassigned(DriverModel d) {
    final routeEmpty = d.assignedRouteId.trim().isEmpty ||
        d.assignedRouteId.toLowerCase() == 'not assigned' ||
        d.assignedRouteName.trim().isEmpty ||
        d.assignedRouteName.toLowerCase() == 'not assigned';
    final busEmpty = d.assignedBusId.trim().isEmpty ||
        d.assignedBusId.toLowerCase() == 'not assigned' ||
        d.assignedBusNumber.trim().isEmpty ||
        d.assignedBusNumber.toLowerCase() == 'not assigned';
    return routeEmpty && busEmpty;
  }

  List<DriverModel> _filter(List<DriverModel> all) {
    return all.where((d) {
      final matchesSearch = _searchQuery.isEmpty ||
          d.name.toLowerCase().contains(_searchQuery) ||
          d.driverId.toLowerCase().contains(_searchQuery);
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Unassigned'
              ? _isUnassigned(d)
              : d.status == _statusFilter);
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _repairAssignments() async {
    setState(() => _repairing = true);
    try {
      final report = await RouteAssignmentService().repairAssignments();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Repair assignments'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                'Fixed: ${report.fixed.length}\n'
                'Unmatched: ${report.unmatched.length}\n'
                'Skipped: ${report.skipped.length}\n\n'
                '${report.fixed.isEmpty ? '' : 'Fixed:\n${report.fixed.take(20).join('\n')}\n\n'}'
                '${report.unmatched.isEmpty ? '' : 'Unmatched:\n${report.unmatched.take(20).join('\n')}\n\n'}'
                '${report.skipped.isEmpty ? '' : 'Skipped:\n${report.skipped.take(20).join('\n')}'}',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _repairing = false);
    }
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
        actions: [
          TextButton.icon(
            onPressed: _repairing ? null : _repairAssignments,
            icon: _repairing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.build_circle_outlined),
            label: const Text('Repair assignments'),
          ),
        ],
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
                  children: [
                    'All',
                    'Active',
                    'Inactive',
                    'On Leave',
                    'Unassigned',
                  ].map((status) {
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
