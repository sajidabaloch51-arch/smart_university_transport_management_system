import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer or SMS app for [phone].
/// Does not rely on [canLaunchUrl] alone (often false on Android 11+).
class PhoneLauncher {
  /// Keep digits and a leading + for international numbers.
  static String sanitize(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return '';
    final buf = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final c = trimmed[i];
      if (c == '+' && buf.isEmpty) {
        buf.write(c);
      } else if (c.compareTo('0') >= 0 && c.compareTo('9') <= 0) {
        buf.write(c);
      }
    }
    return buf.toString();
  }

  static Future<bool> call(String phone, {BuildContext? context}) async {
    final cleaned = sanitize(phone);
    if (cleaned.isEmpty) {
      _toast(context, 'No phone number for this driver');
      return false;
    }
    // Prefer dialer UI (no CALL_PHONE permission needed).
    final uri = Uri.parse('tel:$cleaned');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _toast(context, 'Could not open the phone dialer');
      return ok;
    } catch (e) {
      debugPrint('PhoneLauncher.call failed: $e');
      _toast(context, 'Could not open the phone dialer');
      return false;
    }
  }

  static Future<bool> sms(String phone, {BuildContext? context}) async {
    final cleaned = sanitize(phone);
    if (cleaned.isEmpty) {
      _toast(context, 'No phone number for this driver');
      return false;
    }
    final uri = Uri.parse('sms:$cleaned');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _toast(context, 'Could not open Messages');
      return ok;
    } catch (e) {
      debugPrint('PhoneLauncher.sms failed: $e');
      _toast(context, 'Could not open Messages');
      return false;
    }
  }

  static void _toast(BuildContext? context, String message) {
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
