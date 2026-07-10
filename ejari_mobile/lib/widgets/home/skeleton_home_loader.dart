import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SkeletonHomeLoader extends StatelessWidget {
  const SkeletonHomeLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36),
            _buildHeroSkeleton(),
            const SizedBox(height: 16),
            _buildShimmerBlock(width: double.infinity, height: 58),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildShimmerBlock(height: 48)),
                const SizedBox(width: 10),
                Expanded(child: _buildShimmerBlock(height: 48)),
                const SizedBox(width: 10),
                Expanded(child: _buildShimmerBlock(height: 48)),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionSkeleton(width: 180),
            const SizedBox(height: 12),
            _buildShimmerBlock(width: double.infinity, height: 180),
            const SizedBox(height: 18),
            _buildSectionSkeleton(width: 130),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildShimmerBlock(height: 160)),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerBlock(height: 160)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBlock(width: 150, height: 18),
          const SizedBox(height: 12),
          _buildShimmerBlock(width: double.infinity, height: 100),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildShimmerBlock(height: 70)),
              const SizedBox(width: 10),
              Expanded(child: _buildShimmerBlock(height: 70)),
              const SizedBox(width: 10),
              Expanded(child: _buildShimmerBlock(height: 70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSkeleton({required double width}) {
    return _buildShimmerBlock(width: width, height: 22);
  }

  Widget _buildShimmerBlock({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
