import 'package:flutter/material.dart';
import 'package:navigator/widgets/GeneralUIComponents/loadingCircle/loadingCircle.dart';

class RefreshJourneyPopUpAndroid {
  static Future<void> show(
    BuildContext context, {
    String message = 'Loading...',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingCircle(design: 0),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}