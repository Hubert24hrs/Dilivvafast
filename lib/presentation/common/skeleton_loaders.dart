import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader for cards
class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const SkeletonCard({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Skeleton loader for list items
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          const SkeletonCard(height: 50, width: 50),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonCard(height: 16, width: MediaQuery.of(context).size.width * 0.6),
                const SizedBox(height: 8),
                SkeletonCard(height: 12, width: MediaQuery.of(context).size.width * 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for profile screen
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(
          child: SkeletonCard(height: 100, width: 100, borderRadius: BorderRadius.all(Radius.circular(50))),
        ),
        const SizedBox(height: 16),
        SkeletonCard(height: 20, width: MediaQuery.of(context).size.width * 0.5),
        const SizedBox(height: 8),
        SkeletonCard(height: 16, width: MediaQuery.of(context).size.width * 0.3),
        const SizedBox(height: 32),
        ...List.generate(5, (index) => const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: SkeletonCard(height: 60),
        )),
      ],
    );
  }
}

/// Skeleton loader for ride card
class SkeletonRideCard extends StatelessWidget {
  const SkeletonRideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonCard(height: 20, width: MediaQuery.of(context).size.width * 0.3),
                const SkeletonCard(height: 24, width: 60),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonCard(height: 16, width: double.infinity),
            const SizedBox(height: 8),
            const SkeletonCard(height: 16, width: double.infinity),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonCard(height: 16, width: MediaQuery.of(context).size.width * 0.25),
                SkeletonCard(height: 20, width: MediaQuery.of(context).size.width * 0.2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
