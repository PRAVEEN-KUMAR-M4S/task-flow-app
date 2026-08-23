import 'package:flutter/material.dart';

/// A shimmer-animated skeleton placeholder used while content is loading.
///
/// Wraps a [ShaderMask] with a linear gradient that sweeps left-to-right
/// to produce the classic skeleton shimmer effect. Use it to build
/// placeholder shapes (rectangles, circles, rounded boxes) that approximate
/// the layout of the real content.
///
/// Example:
/// ```dart
/// SkeletonLoader(
///   child: Column(
///     children: [
///       SkeletonBox(height: 20, width: double.infinity),
///       SizedBox(height: 8),
///       SkeletonBox(height: 14, width: 200),
///     ],
///   ),
/// )
/// ```
class SkeletonLoader extends StatefulWidget {
  final Widget child;

  const SkeletonLoader({super.key, required this.child});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A skeleton placeholder box — rounded rectangle.
class SkeletonBox extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade400, // masked by ShaderMask
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A skeleton placeholder circle.
class SkeletonCircle extends StatelessWidget {
  final double radius;

  const SkeletonCircle({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
