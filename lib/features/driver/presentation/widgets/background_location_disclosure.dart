import 'package:flutter/material.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Prominent disclosure for background location, shown before the OS prompt.
///
/// Google Play requires this for any app requesting ACCESS_BACKGROUND_LOCATION:
/// the user has to be told, inside the app and *before* the system permission
/// dialog appears, that location is collected in the background and what it is
/// used for. A mention in the privacy policy does not satisfy the policy, and
/// shipping without this is the most common rejection reason for delivery apps.
///
/// Returns true when the driver agrees to continue to the system prompt.
/// Declining is a real choice: the driver stays offline rather than being
/// pushed into a permission they did not want.
Future<bool> showBackgroundLocationDisclosure(BuildContext context) async {
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _BackgroundLocationDisclosureDialog(),
  );
  return agreed ?? false;
}

class _BackgroundLocationDisclosureDialog extends StatelessWidget {
  const _BackgroundLocationDisclosureDialog();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.my_location, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dilivvafast needs your location',
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dilivvafast collects location data to enable live delivery '
              'tracking, even when the app is closed or not in use.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const _DisclosurePoint(
              icon: Icons.visibility,
              text: 'Customers can watch your bike move on the map while you '
                  'are delivering their package.',
            ),
            const _DisclosurePoint(
              icon: Icons.assignment_turned_in,
              text: 'We match you with nearby delivery jobs.',
            ),
            const _DisclosurePoint(
              icon: Icons.schedule,
              text: 'Tracking only runs while you are online. Go offline and '
                  'it stops.',
            ),
            const SizedBox(height: 16),
            Text(
              'On the next screen, choose "Allow all the time" to keep '
              'tracking working when you switch apps. You can decline, or '
              'change this later in your phone settings — you will still be '
              'able to work, but customers may lose sight of you when you '
              'leave the app.',
              style: textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Not now',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _DisclosurePoint extends StatelessWidget {
  const _DisclosurePoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
