import 'package:flutter/services.dart';

/// Flutter autofill helpers for Google Password Manager.
///
/// Autofill is always left enabled at the Android Activity level. Call
/// [commitSave] only after Auth + Firestore succeed, and [cancelSave] when
/// creation/login fails — always while the credential TextFields are still
/// mounted and still hold their values.
class AutofillPolicy {
  AutofillPolicy._();

  static const _channel = MethodChannel('sutms/autofill');

  /// Ensures the Activity allows autofill (never blocks it).
  static Future<void> enableNormalAutofill() async {
    try {
      await _channel.invokeMethod<void>('setAutofillEnabled', {
        'enabled': true,
      });
    } on MissingPluginException {
      // Desktop / web / tests.
    } catch (_) {}
  }

  /// Kept for call-site compatibility — autofill stays ON (user wants save).
  static Future<void> disableForAdminProvisioning() async {
    await enableNormalAutofill();
  }

  /// Offers "Save password?" then briefly yields so the system UI can appear
  /// before the screen is popped / navigated away.
  static Future<void> commitSave() async {
    TextInput.finishAutofillContext(shouldSave: true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  /// Cancels the autofill context (failed create / failed login).
  static Future<void> cancelSave() async {
    TextInput.finishAutofillContext(shouldSave: false);
  }
}
