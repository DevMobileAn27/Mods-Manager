import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Shared desktop card feedback for character and file grids.
class LibraryCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onSecondaryTapDown;

  const LibraryCard({
    super.key,
    required this.child,
    this.onTap,
    this.onSecondaryTapDown,
  });

  @override
  State<LibraryCard> createState() => _LibraryCardState();
}

class _LibraryCardState extends State<LibraryCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: hovered ? AppColors.primary : AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onSecondaryTapDown: widget.onSecondaryTapDown,
        onHover: (value) => setState(() => hovered = value),
        borderRadius: BorderRadius.circular(6),
        hoverColor: AppColors.primary.withValues(alpha: 0.08),
        child: widget.child,
      ),
    ),
  );
}
