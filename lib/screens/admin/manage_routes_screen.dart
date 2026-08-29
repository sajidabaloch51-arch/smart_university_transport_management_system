import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart'; // Using driver provider for route data temporarily

class ManageRoutesScreen extends StatelessWidget {
  const ManageRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Routes')),
      body: Consumer<DriverProvider>(
        builder: (context, provider, child) {
          final route = provider.assignedRoute;
          if (route == null) return const Center(child: Text('No routes configured.'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text(route.routeNumber, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(route.routeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${route.startPoint} ↔ ${route.endPoint}\n${route.stops.length} Stops | ${route.totalDistance}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20), 
                        onPressed: () => context.push('/add-edit-route', extra: route)
                      ),
                      IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ],
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
}
