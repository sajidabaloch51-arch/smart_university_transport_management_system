import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/bus_provider.dart';
import '../../widgets/bus_card.dart';
import '../../widgets/list_skeleton.dart';
import '../../models/bus_model.dart';
import '../../utils/perf_log.dart';

class ManageBusesScreen extends StatefulWidget {
  const ManageBusesScreen({super.key});

  @override
  State<ManageBusesScreen> createState() => _ManageBusesScreenState();
}

class _ManageBusesScreenState extends State<ManageBusesScreen> {
  late final Stream<List<BusModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<BusProvider>().streamBuses();
    PerfLog.start('screen_ManageBuses');
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = context.read<BusProvider>();
    final initial =
        busProvider.cachedBuses.isEmpty ? null : busProvider.cachedBuses;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Buses')),
      body: CachedStreamList<List<BusModel>>(
        stream: _stream,
        initialData: initial,
        emptyMessage: 'No buses found.',
        isEmpty: (list) => list.isEmpty,
        onRefresh: () => busProvider.refreshBuses(),
        builder: (context, buses) {
          PerfLog.end('screen_ManageBuses',
              label: 'first_data', count: buses.length);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              return BusCard(
                bus: buses[index],
                onEdit: () =>
                    context.push('/add-edit-bus', extra: buses[index]),
                onDelete: () => busProvider.deleteBus(buses[index].id),
                onToggleActive: () =>
                    busProvider.toggleBusActive(buses[index].id),
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
