import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/route_provider.dart';
import '../../models/route_model.dart';
import '../../services/route_assignment_service.dart';
import '../../utils/perf_log.dart';
import '../../widgets/list_skeleton.dart';

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});

  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  bool _migrating = false;
  late final Stream<List<RouteModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<RouteProvider>().streamRoutes();
    PerfLog.start('screen_ManageRoutes');
  }

  Future<void> _runMigration() async {
    setState(() => _migrating = true);
    try {
      final n =
          await RouteAssignmentService().migrateAssignmentsFromExistingData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n == 0
                ? 'No routes needed updates (already linked or no source data).'
                : 'Synced driver assignment onto $n route(s).',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _migrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = context.read<RouteProvider>();
    final initial =
        routeProvider.cachedRoutes.isEmpty ? null : routeProvider.cachedRoutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routes'),
        actions: [
          TextButton.icon(
            onPressed: _migrating ? null : _runMigration,
            icon: _migrating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: const Text('Sync drivers'),
          ),
        ],
      ),
      body: CachedStreamList<List<RouteModel>>(
        stream: _stream,
        initialData: initial,
        emptyMessage: 'No routes configured.',
        isEmpty: (list) => list.isEmpty,
        onRefresh: () => routeProvider.refreshRoutes(),
        builder: (context, routes) {
          PerfLog.end('screen_ManageRoutes',
              label: 'first_data', count: routes.length);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      route.routeNumber,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    route.routeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${route.startLocation} ↔ ${route.endLocation}\n'
                    'Driver: ${route.displayDriverName}'
                    '${route.busNo.isNotEmpty ? ' · Bus ${route.busNo}' : ''}\n'
                    '${route.viaStops.length} via stops | ${route.isActive ? "ON" : "OFF"}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: route.isActive,
                        activeThumbColor: Colors.green,
                        onChanged: (_) =>
                            routeProvider.toggleRouteActive(route.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            context.push('/add-edit-route', extra: route),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _confirmDelete(
                          context,
                          routeProvider,
                          route.id,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-edit-route'),
        icon: const Icon(Icons.add_road),
        label: const Text('Add Route'),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    RouteProvider provider,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text('Remove this route permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRoute(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
