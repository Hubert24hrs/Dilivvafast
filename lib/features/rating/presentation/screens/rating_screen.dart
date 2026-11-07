import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _field = Color(0xFFF3F4F6);
const _lime = Color(0xFFC1F11D);

/// Compliments a customer can give with 4 or 5 stars, keyed as the server
/// counts them (RATING_TAGS in functions/src/index.ts).
const ratingCompliments = {
  'fast_delivery': 'Fast delivery',
  'careful_with_package': 'Careful with the package',
  'polite': 'Polite',
  'good_communication': 'Good communication',
  'on_time_pickup': 'On time at pickup',
};

/// Rate the courier after delivery, inDrive-style: stars first, then — for a
/// good delivery — tap the compliments that apply, and an optional comment.
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 0;
  final _tags = <String>{};
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        title: const Text(
          'Rate your courier',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      // Always on screen: with compliments and a comment open, a button at the
      // end of the list sat below the fold.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
              style: FilledButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: _ink,
                disabledBackgroundColor: _field,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: _ink,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Submit rating'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const Icon(Icons.delivery_dining_rounded, color: _ink, size: 64),
            const SizedBox(height: 16),
            const Text(
              'How was your delivery?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your rating helps good couriers get more jobs',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  tooltip: '$star star${star == 1 ? '' : 's'}',
                  iconSize: 46,
                  onPressed: () => setState(() {
                    _rating = star;
                    if (star < 4) _tags.clear();
                  }),
                  icon: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFF5B301),
                  ),
                );
              }),
            ),
            Text(
              _ratingLabel(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_rating >= 4) ...[
              const SizedBox(height: 20),
              const Text(
                'What went well?',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in ratingCompliments.entries)
                    FilterChip(
                      label: Text(entry.value),
                      selected: _tags.contains(entry.key),
                      onSelected: (on) => setState(() {
                        on ? _tags.add(entry.key) : _tags.remove(entry.key);
                      }),
                      showCheckmark: false,
                      selectedColor: _lime,
                      backgroundColor: _field,
                      side: BorderSide.none,
                      labelStyle: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 300,
              style: const TextStyle(color: _ink),
              decoration: InputDecoration(
                hintText: _rating > 0 && _rating < 4
                    ? 'What could have been better? (optional)'
                    : 'Add a comment (optional)',
                filled: true,
                fillColor: _field,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel() {
    return switch (_rating) {
      1 => 'Poor',
      2 => 'Fair',
      3 => 'Good',
      4 => 'Great',
      5 => 'Excellent!',
      _ => 'Tap a star to rate',
    };
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    try {
      final comment = _commentController.text.trim();
      final result = await ref
          .read(courierRepositoryProvider)
          .rateOrder(
            widget.orderId,
            _rating,
            comment.isEmpty ? null : comment,
            tags: _tags.toList(),
          );
      if (!mounted) return;
      // rateOrder returns its failure rather than throwing; show it.
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: context.palette.danger,
          ),
        ),
        (_) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your rating!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Rating submit failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not save your rating. Please try again.',
            ),
            backgroundColor: context.palette.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
