import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// SOS Alert Widget — Emergency button for active deliveries.
/// Creates a Firestore document in `sos_alerts` which triggers Cloud Function notifications.
class SosAlertButton extends StatelessWidget {
  final String? orderId;
  final double size;

  const SosAlertButton({super.key, this.orderId, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showSosConfirmation(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.errorColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.errorColor.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sos, color: Colors.white, size: 24),
            Text('SOS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: size > 48 ? 8 : 6,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showSosConfirmation(BuildContext context) {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SosConfirmDialog(orderId: orderId),
    );
  }
}

class _SosConfirmDialog extends StatefulWidget {
  final String? orderId;

  const _SosConfirmDialog({this.orderId});

  @override
  State<_SosConfirmDialog> createState() => _SosConfirmDialogState();
}

class _SosConfirmDialogState extends State<_SosConfirmDialog> {
  bool _isSending = false;
  String _selectedReason = 'I feel unsafe';

  final List<String> _reasons = [
    'I feel unsafe',
    'Driver behaviour concern',
    'Accident or injury',
    'Package theft / tampering',
    'Vehicle breakdown',
    'Other emergency',
  ];

  Future<void> _triggerSos() async {
    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Try to get current location
      String address = 'Location unavailable';
      double? lat;
      double? lng;

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
        address = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      } catch (_) {
        // Location not critical for SOS
      }

      await FirebaseFirestore.instance.collection('sos_alerts').add({
        'userId': user.uid,
        'userEmail': user.email,
        'orderId': widget.orderId ?? '',
        'reason': _selectedReason,
        'address': address,
        'latitude': lat,
        'longitude': lng,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SOS alert sent! Our team has been notified and will respond shortly.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('SOS error: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS. Call emergency: 112\nError: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.errorColor.withValues(alpha: 0.15),
            ),
            child:
                const Icon(Icons.sos, color: AppTheme.errorColor, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Emergency SOS',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ).animate().fadeIn(duration: 200.ms).shake(hz: 2, duration: 300.ms),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will immediately alert our support team with your location.',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text('Reason:',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_reasons.length, (index) {
            final reason = _reasons[index];
            final isSelected = _selectedReason == reason;
            return GestureDetector(
              onTap: () => setState(() => _selectedReason = reason),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.errorColor.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.errorColor.withValues(alpha: 0.4)
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected ? AppTheme.errorColor : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(reason,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _triggerSos,
          icon: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.warning_rounded, size: 16),
          label: Text(_isSending ? 'Sending...' : 'Send SOS Alert'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
