import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class LibraryTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const LibraryTabBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 260,
    height: 48,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.tabTrack,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(color: AppColors.tabShadow, blurRadius: 16, spreadRadius: 1),
      ],
    ),
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(end: selectedIndex.toDouble()),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      builder: (context, position, child) => Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment(-1 + 2 * position, 0),
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Transform.scale(
                scale: 1 - 0.15 * math.sin(math.pi * position),
                child: DecoratedBox(
                  key: const ValueKey('library-tab-indicator'),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      AppColors.primary,
                      Colors.black,
                      0.20 * math.sin(math.pi * position),
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _tab(0, Icons.extension_outlined, 'Mods', 1 - position),
              _tab(1, Icons.archive_outlined, 'Download', position),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _tab(int index, IconData icon, String label, double activeAmount) {
    final color = Color.lerp(
      AppColors.textSecondary,
      AppColors.onPrimary,
      activeAmount,
    );
    return Expanded(
      child: Semantics(
        selected: selectedIndex == index,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onChanged(index),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
