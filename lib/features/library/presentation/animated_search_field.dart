import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_strings.dart';

class AnimatedSearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const AnimatedSearchField({super.key, required this.onChanged});

  @override
  State<AnimatedSearchField> createState() => _AnimatedSearchFieldState();
}

class _AnimatedSearchFieldState extends State<AnimatedSearchField> {
  static const _collapsedSize = 42.0;
  static const _expandedWidth = 250.0;
  static const _animationDuration = Duration(milliseconds: 320);
  static const _collapseDelay = Duration(milliseconds: 1500);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _collapseTimer;
  bool _expanded = true;
  bool _hovered = false;
  bool _hasText = false;

  BorderRadius get _borderRadius => BorderRadius.circular(_expanded ? 14 : 21);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
    _scheduleCollapse();
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _expand();
    } else {
      _scheduleCollapse();
    }
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged('');
    _focusNode.requestFocus();
    _scheduleCollapse();
  }

  void _expand({bool focus = false}) {
    _collapseTimer?.cancel();
    if (!_expanded) setState(() => _expanded = true);
    if (focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _scheduleCollapse() {
    _collapseTimer?.cancel();
    if (!_expanded || _hovered || _controller.text.isNotEmpty) return;
    _collapseTimer = Timer(_collapseDelay, () {
      if (!mounted || _hovered || _controller.text.isNotEmpty) return;
      _focusNode.unfocus();
      setState(() => _expanded = false);
    });
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) {
      _hovered = true;
      _expand();
    },
    onExit: (_) {
      _hovered = false;
      _scheduleCollapse();
    },
    child: AnimatedContainer(
      key: const ValueKey('library-search'),
      duration: _animationDuration,
      curve: Curves.easeInOutCubic,
      width: _expanded ? _expandedWidth : _collapsedSize,
      height: _collapsedSize,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.tabTrack,
        border: Border.all(color: AppColors.border),
        borderRadius: _borderRadius,
      ),
      child: Row(
        children: [
          if (_expanded)
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (value) {
                  widget.onChanged(value);
                  if (value.isEmpty) {
                    _scheduleCollapse();
                  } else {
                    _collapseTimer?.cancel();
                  }
                },
                decoration: InputDecoration(
                  hintText: AppStrings.of(context).searchHint,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.only(left: 14),
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.text),
              ),
            ),
          SizedBox(
            width: _collapsedSize - 2,
            height: _collapsedSize - 2,
            child: IconButton(
              tooltip: _hasText
                  ? AppStrings.of(context).clearSearch
                  : AppStrings.of(context).search,
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: _borderRadius),
              ).copyWith(animationDuration: _animationDuration),
              onPressed: _hasText ? _clearText : () => _expand(focus: true),
              icon: Icon(
                _hasText ? Icons.close : Icons.search,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
