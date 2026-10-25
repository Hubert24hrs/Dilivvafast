import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 0;
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
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        title: Text(
          'Rate Delivery',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining, color: context.palette.brand, size: 64),
            const SizedBox(height: 20),
            Text(
              'How was your delivery?',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback helps us improve',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starNum = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starNum),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      starNum <= _rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFAB00),
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _ratingLabel(),
              style: const TextStyle(
                color: Color(0xFFFFAB00),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Comment
            Container(
              decoration: BoxDecoration(
                color: context.palette.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.palette.border),
              ),
              child: TextField(
                controller: _commentController,
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: TextStyle(color: context.palette.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rating > 0
                      ? context.palette.brand
                      : context.palette.surfaceRaised,
                  foregroundColor: context.palette.surfaceBase,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: context.palette.surfaceBase,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
      _ => 'Tap to rate',
    };
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    try {
      final courierRepo = ref.read(courierRepositoryProvider);
      final result = await courierRepo.rateOrder(
        widget.orderId,
        _rating,
        _commentController.text.trim(),
      );
      if (!mounted) return;
      // This used to say "thank you" whatever happened — rateOrder returns
      // its failure rather than throwing, and the result was ignored.
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
              backgroundColor: Color(0xFF4CAF50),
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
