import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum BusStatus { inTransit, delayed, scheduled }

class BusRouteCard extends StatelessWidget {
  final String busName;
  final String busCode;
  final BusStatus status;
  final String driverName;
  final String driverPhone;
  final String startLocation;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String? currentLocation;
  final bool isPrimary;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;
  final VoidCallback? onCancel;
  final VoidCallback? onShowDriverDetails;

  const BusRouteCard({
    super.key,
    required this.busName,
    required this.busCode,
    required this.status,
    required this.driverName,
    required this.driverPhone,
    required this.startLocation,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    this.currentLocation,
    this.isPrimary = false,
    this.onCall,
    this.onChat,
    this.onTap,
    this.onSelect,
    this.onCancel,
    this.onShowDriverDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPrimary ? 4 : 2,
      shadowColor: isPrimary ? AppColors.primary.withValues(alpha: 0.4) : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPrimary 
            ? const BorderSide(color: AppColors.primary, width: 2) 
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildDriverBar(context),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _buildRouteTimeline(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Color statusColor;
    String statusText;

    switch (status) {
      case BusStatus.inTransit:
        statusColor = Colors.green;
        statusText = "In Transit";
        break;
      case BusStatus.delayed:
        statusColor = Colors.orange;
        statusText = "Delayed";
        break;
      case BusStatus.scheduled:
        statusColor = Colors.blueGrey;
        statusText = "Scheduled";
        break;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    busName,
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (isPrimary) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "PRIMARY",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  busCode,
                  style: const TextStyle(
                    color: AppColors.primary, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverBar(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.blueGrey, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Driver",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Text(
                driverName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        _actionButton(Icons.call, Colors.green, onCall),
        const SizedBox(width: 8),
        _actionButton(Icons.chat_bubble_outline_rounded, AppColors.primary, onChat),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!isPrimary)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.route_rounded, size: 18),
              label: const Text("Select Route"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          )
        else ...[
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Selected",
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text("Cancel"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShowDriverDetails,
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            label: const Text("Details"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback? onPressed) {
    final enabled = onPressed != null;
    final tip = icon == Icons.call
        ? (enabled ? 'Call driver' : 'No driver phone available')
        : (enabled ? 'Message driver' : 'No driver phone available');
    return Tooltip(
      message: tip,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: enabled ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: enabled ? color : Colors.grey.shade400,
            size: 20,
          ),
          onPressed: onPressed,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildRouteTimeline() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                const Icon(Icons.radio_button_checked, size: 14, color: AppColors.primary),
                Expanded(
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.2)],
                      ),
                    ),
                  ),
                ),
                if (status == BusStatus.inTransit) ...[
                  const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary],
                        ),
                      ),
                    ),
                  ),
                ],
                const Icon(Icons.location_on, size: 14, color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _timelineText(startLocation, departureTime, isMain: true),
                if (status == BusStatus.inTransit)
                  _timelineText(currentLocation ?? "Moving on Route", "Live", isHighlight: true),
                _timelineText(destination, arrivalTime, isMain: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineText(String location, String time, {bool isMain = false, bool isHighlight = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            location,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isMain ? FontWeight.w700 : FontWeight.w500,
              color: isHighlight ? Colors.redAccent : const Color(0xFF334155),
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.redAccent : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
