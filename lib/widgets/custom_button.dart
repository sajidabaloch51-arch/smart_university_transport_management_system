import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';

/// Primary blue action button with **instant** press feedback.
///
/// Shows a spinner as soon as [onPressed] is tapped (before awaited network
/// work), so the UI never feels like the blue button "lagged".
class CustomButton extends StatefulWidget {
  final String text;
  final FutureOr<void> Function()? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.icon,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _localBusy = false;

  bool get _busy => widget.isLoading || _localBusy;

  Future<void> _handleTap() async {
    final cb = widget.onPressed;
    if (cb == null || _busy) return;

    // Instant haptic + visual so the tap never feels ignored.
    HapticFeedback.lightImpact();
    setState(() => _localBusy = true);

    try {
      final result = cb();
      if (result is Future) {
        await result;
      } else {
        // Let parent setState(isLoading) paint before we drop local busy.
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      if (mounted) setState(() => _localBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? AppColors.primary;
    final busy = _busy;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: (widget.onPressed == null || busy) ? null : _handleTap,
        style: ButtonStyle(
          animationDuration: Duration.zero,
          splashFactory: NoSplash.splashFactory,
          elevation: const WidgetStatePropertyAll(2),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled) || busy) {
              return base.withValues(alpha: 0.72);
            }
            if (states.contains(WidgetState.pressed)) {
              return Color.lerp(base, Colors.black, 0.18)!;
            }
            return base;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        child: busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
