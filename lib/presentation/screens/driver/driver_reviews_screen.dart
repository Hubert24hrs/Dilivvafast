import 'package:fast_delivery/core/models/rating_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DriverReviewsScreen extends ConsumerStatefulWidget {
  const DriverReviewsScreen({super.key});

  @override
  ConsumerState<DriverReviewsScreen> createState() => _DriverReviewsScreenState();
}

class _DriverReviewsScreenState extends ConsumerState<DriverReviewsScreen> {
  Map<String, dynamic> _stats = {'average': 5.0, 'total': 0, 'distribution': <int, int>{}};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final driverId = ref.read(currentUserIdProvider);
    if (driverId == null) return;

    final stats = await ref.read(ratingServiceProvider).getDriverRatingStats(driverId);
    if (mounted) {
      setState(() => _stats = stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverId = ref.watch(currentUserIdProvider);
    Stream<List<RatingModel>>? ratingsStream;
    if (driverId != null) {
      ratingsStream = ref.watch(ratingServiceProvider).getDriverRatings(driverId);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('My Reviews', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Summary Card
            _buildRatingSummaryCard(),
            const SizedBox(height: 24),

            // Rating Distribution
            _buildRatingDistribution(),
            const SizedBox(height: 24),

            // Reviews List
            Text(
              'All Reviews',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<RatingModel>>(
              stream: ratingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ratings = snapshot.data ?? [];

                if (ratings.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.star_border, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No reviews yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) => _buildReviewTile(ratings[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummaryCard() {
    final average = (_stats['average'] as double?) ?? 5.0;
    final total = (_stats['total'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    average.toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Icon(Icons.star, color: Colors.white, size: 28),
                  ),
                ],
              ),
              Text(
                '$total ${total == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                color: index < average.floor() ? Colors.white : Colors.white38,
                size: 24,
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildRatingDistribution() {
    final distribution = (_stats['distribution'] as Map<int, int>?) ?? {};
    final total = (_stats['total'] as int?) ?? 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rating Breakdown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            final star = 5 - index;
            final count = distribution[star] ?? 0;
            final percentage = total > 0 ? count / total : 0.0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('$star', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(Colors.amber),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$count',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewTile(RatingModel rating) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passenger',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      dateFormat.format(rating.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          if (rating.feedback != null && rating.feedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              rating.feedback!,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
          if (rating.tip != null && rating.tip! > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💰 ₦${rating.tip!.toStringAsFixed(0)} tip',
                style: const TextStyle(color: Colors.green, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
