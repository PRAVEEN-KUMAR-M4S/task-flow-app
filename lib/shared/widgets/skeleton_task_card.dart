import 'package:flutter/material.dart';
import 'package:task_flow/shared/widgets/skeleton_loader.dart';

/// Skeleton placeholder that matches the layout of [TaskCard].
class SkeletonTaskCard extends StatelessWidget {
  const SkeletonTaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: SkeletonBox(height: 16)),
                const SizedBox(width: 8),
                SkeletonBox(height: 22, width: 50, borderRadius: 10),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            SkeletonBox(height: 12, width: double.infinity),
            const SizedBox(height: 6),
            SkeletonBox(height: 12, width: 160),
            const SizedBox(height: 12),
            // Bottom row: status + priority + date + avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SkeletonBox(height: 22, width: 70, borderRadius: 10),
                    const SizedBox(width: 8),
                    SkeletonBox(height: 16, width: 60),
                  ],
                ),
                Row(
                  children: [
                    SkeletonBox(height: 12, width: 50),
                    const SizedBox(width: 8),
                    const SkeletonCircle(radius: 12),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
