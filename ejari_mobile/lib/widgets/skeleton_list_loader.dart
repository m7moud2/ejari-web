import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Generic skeleton loader for list/detail screens.
class SkeletonListLoader extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonListLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.screenPadding),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _SkeletonRow(height: itemHeight),
    );
  }
}

class _SkeletonRow extends StatefulWidget {
  final double height;
  const _SkeletonRow({required this.height});

  @override
  State<_SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<_SkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: [
                AppTheme.inputFillColor,
                AppTheme.borderColor.withOpacity(0.5),
                AppTheme.inputFillColor,
              ],
            ),
          ),
        );
      },
    );
  }
}
