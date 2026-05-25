import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Optimized image widget with caching and loading states
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's a network image or asset
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => 
            placeholder ?? 
            Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget: (context, url, error) => 
            errorWidget ??
            Container(
              color: Colors.grey.shade900,
              child: const Icon(Icons.error, color: Colors.grey),
            ),
        // Performance optimizations
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
      );
    }

    // Asset image
    return Image.asset(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => 
          errorWidget ?? 
          const Icon(Icons.error),
    );
  }
}

/// Circle avatar with optimized image loading
class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: placeholder ?? Icon(Icons.person, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade900,
      child: ClipOval(
        child: OptimizedImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
