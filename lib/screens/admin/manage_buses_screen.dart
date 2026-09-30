import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/bus_provider.dart';
import '../../widgets/bus_card.dart';
import '../../models/bus_model.dart';

class ManageBusesScreen extends StatelessWidget {
  const ManageBusesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Buses')),
      body: StreamBuilder<List<BusModel>>(
        stream: busProvider.streamBuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final buses = snapshot.data ?? [];
          if (buses.isEmpty) {
            return const Center(child: Text('No buses found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              return BusCard(
                bus: buses[index],
                onEdit: () => context.push('/add-edit-bus', extra: buses[index]),
                onDelete: () => busProvider.deleteBus(buses[index].id),
                onToggleActive: () => busProvider.toggleBusActive(buses[index].id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-edit-bus'),
        icon: const Icon(Icons.add),
        label: const Text('Add Bus'),
      ),
    );
  }
}
