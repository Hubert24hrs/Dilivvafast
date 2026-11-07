import 'package:flutter/material.dart';

/// Reasons a customer can give for cancelling, inDrive-style.
const customerCancelReasons = [
  'It is taking too long',
  'The offers are too expensive',
  'I changed my mind',
  'Wrong pickup or drop-off address',
  'I found another way to send it',
  'The courier asked me to cancel',
  'Other',
];

/// Reasons a courier can give for dropping a job before pickup.
const courierCancelReasons = [
  'The customer is not responding',
  'The package is not ready',
  'The package is too big or heavy',
  'Problem with my vehicle',
  'The pickup is too far',
  'Other',
];

/// Asks why, inDrive-style: a bottom sheet of reasons, then a confirm button.
/// Returns the chosen reason, or null if the person backs out.
Future<String?> showReasonSheet(
  BuildContext context, {
  required String title,
  required List<String> reasons,
  required String confirmLabel,
  String? message,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReasonSheet(
      title: title,
      reasons: reasons,
      confirmLabel: confirmLabel,
      message: message,
    ),
  );
}

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({
    required this.title,
    required this.reasons,
    required this.confirmLabel,
    this.message,
  });

  final String title;
  final List<String> reasons;
  final String confirmLabel;
  final String? message;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  static const _ink = Color(0xFF111827);
  String? _picked;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.message!,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: RadioGroup<String>(
                groupValue: _picked,
                onChanged: (v) => setState(() => _picked = v),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final reason in widget.reasons)
                      RadioListTile<String>(
                        value: reason,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _ink,
                        title: Text(
                          reason,
                          style: const TextStyle(fontSize: 16, color: _ink),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _picked == null
                    ? null
                    : () => Navigator.of(context).pop(_picked),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(widget.confirmLabel),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: _ink),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
