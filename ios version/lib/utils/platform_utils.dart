// lib/utils/platform_utils.dart
// iOS-specific platform helpers and adaptive UI utilities
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatformUtils {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  /// Light haptic tap — use on selections, toggles
  static void hapticLight() {
    if (isIOS) HapticFeedback.lightImpact();
  }

  /// Medium haptic — use on button presses
  static void hapticMedium() {
    if (isIOS) HapticFeedback.mediumImpact();
  }

  /// Heavy haptic — use on confirmations / order placed
  static void hapticHeavy() {
    if (isIOS) HapticFeedback.heavyImpact();
  }

  /// Success haptic notification
  static void hapticSuccess() {
    HapticFeedback.selectionClick();
  }

  /// Shows a native-adaptive dialog:
  /// CupertinoAlertDialog on iOS, AlertDialog on Android
  static Future<T?> showAdaptiveDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    String confirmLabel = 'OK',
    String? cancelLabel,
    bool destructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    if (isIOS) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (cancelLabel != null)
              CupertinoDialogAction(
                isDefaultAction: false,
                onPressed: () {
                  Navigator.pop(context);
                  onCancel?.call();
                },
                child: Text(cancelLabel),
              ),
            CupertinoDialogAction(
              isDestructiveAction: destructive,
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                onConfirm?.call();
              },
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
    }
    return showDialog<T>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelLabel != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onCancel?.call();
              },
              child: Text(cancelLabel),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            child: Text(
              confirmLabel,
              style: TextStyle(color: destructive ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }

  /// iOS-native scroll physics — bouncing on iOS, clamping on Android
  static ScrollPhysics get scrollPhysics => isIOS
      ? const BouncingScrollPhysics()
      : const ClampingScrollPhysics();
}
