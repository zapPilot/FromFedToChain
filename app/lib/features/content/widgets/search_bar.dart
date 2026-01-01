import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';

/// Custom search bar widget for filtering episodes
class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String hintText;
  final String? initialValue;

  const SearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.hintText = 'Search...',
    this.initialValue,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _lastText = widget.initialValue ?? '';

    // Listen to text changes
    _controller.addListener(() {
      final currentText = _controller.text;
      // Only call callback if text actually changed (avoid duplicate calls)
      if (currentText != _lastText) {
        _lastText = currentText;
        widget.onSearchChanged(currentText);
        setState(() {}); // Trigger rebuild to show/hide suffix icon
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTheme.bodyMedium.copyWith(
            color: AppTheme.onSurfaceColor.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.onSurfaceColor.withOpacity(0.6),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? Semantics(
                  label: 'Clear search',
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _controller.clear();
                        // onSearchChanged('') is automatically called by _controller.addListener
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.clear,
                          color: AppTheme.onSurfaceColor.withOpacity(0.6),
                          size:
                              32.0, // Increased size for accessibility compliance
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          filled: true,
          fillColor: AppTheme.cardColor.withOpacity(0.5),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          // onSearchChanged is already handled by _controller.addListener
          // onSubmitted should only handle submission-specific actions
          _focusNode.unfocus();
        },
      ),
    );
  }
}
