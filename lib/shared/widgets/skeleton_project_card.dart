import 'package:flutter/material.dart';
import 'package:task_flow/shared/widgets/skeleton_loader.dart';

/// Skeleton placeholder that matches the layout of [ProjectCard].
class SkeletonProjectCard extends StatelessWidget {
  const SkeletonProjectCard({super.key});

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
              children: [
                Expanded(
                  child: SkeletonBox(height: 18, width: double.infinity),
                ),
                const SizedBox(width: 8),
                SkeletonBox(height: 24, width: 60, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 10),
            // Description lines
            SkeletonBox(height: 12, width: double.infinity),
            const SizedBox(height: 6),
            SkeletonBox(height: 12, width: 200),
            const SizedBox(height: 12),
            // Bottom row: chips + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SkeletonBox(height: 24, width: 50, borderRadius: 12),
                    const SizedBox(width: 6),
                    SkeletonBox(height: 24, width: 50, borderRadius: 12),
                    const SizedBox(width: 6),
                    SkeletonBox(height: 24, width: 50, borderRadius: 12),
                  ],
                ),
                SkeletonBox(height: 12, width: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
