import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../theme/app_colors.dart';

class BusCard extends StatelessWidget {
  final BusModel bus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onToggleActive;

  const BusCard({
    super.key,
    required this.bus,
    required this.onEdit,
    required this.onDelete,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.directions_bus, color: Colors.purple),
        ),
        title: Text(bus.busNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(bus.isActive ? 'ON / Active' : 'OFF / Inactive'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: bus.isActive,
              activeThumbColor: Colors.green,
              onChanged: onToggleActive == null ? null : (_) => onToggleActive!(),
            ),
            IconButton(icon: const Icon(Icons.edit, color: AppColors.primary, size: 20), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete, color: AppColors.error, size: 20), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
