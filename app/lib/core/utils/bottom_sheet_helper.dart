import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';

/// Helper class for displaying bottom sheets with consistent styling.
///
/// Provides static methods to show bottom sheets that match the app's
/// design system, reducing duplication across screens.
class BottomSheetHelper {
  /// Shows a modal bottom sheet with app-standard styling.
  ///
  /// [context] - The build context.
  /// [builder] - The widget builder for the content.
  /// [isDismissible] - Whether the sheet can be dismissed by tapping outside.
  /// [enableDrag] - Whether the sheet can be dragged to dismiss.
  /// [isScrollControlled] - Whether the sheet should size itself to fit content.
  static Future<T?> showAppBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: builder,
    );
  }

  /// Shows a scrollable bottom sheet that can expand to most of the screen.
  ///
  /// Useful for content lists or long forms.
  static Future<T?> showScrollableBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    double maxHeightFactor = 0.9,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
      ),
      builder: builder,
    );
  }
}
