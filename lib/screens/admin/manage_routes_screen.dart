import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/route_provider.dart';
import '../../models/route_model.dart';

class ManageRoutesScreen extends StatelessWidget {
  const ManageRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Routes')),
      body: StreamBuilder<List<RouteModel>>(
        stream: routeProvider.streamRoutes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final routes = snapshot.data ?? [];
          if (routes.isEmpty) {
            return const Center(child: Text('No routes configured.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text(route.routeNumber, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(route.routeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${route.startLocation} ↔ ${route.endLocation}\n${route.viaStops.length} via stops | ${route.isActive ? "ON" : "OFF"}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: route.isActive,
                        activeThumbColor: Colors.green,
                        onChanged: (_) => routeProvider.toggleRouteActive(route.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20), 
                        onPressed: () => context.push('/add-edit-route', extra: route)
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red), 
                        onPressed: () => _confirmDelete(context, routeProvider, route.id)
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

  void _confirmDelete(BuildContext context, RouteProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text('Are you sure you want to remove this route?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteRoute(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Route deleted'), backgroundColor: Colors.red),
              );
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}
