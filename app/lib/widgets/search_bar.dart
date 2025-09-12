import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();

    // Listen to text changes
    _controller.addListener(() {
      widget.onSearchChanged(_controller.text);
      setState(() {}); // Trigger rebuild to show/hide suffix icon
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
                        widget.onSearchChanged('');
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.clear,
                          color: AppTheme.onSurfaceColor.withOpacity(0.6),
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
          widget.onSearchChanged(value);
          _focusNode.unfocus();
        },
      ),
    );
  }
}
