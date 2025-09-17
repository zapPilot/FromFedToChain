/// Compatibility export for ContentService
/// This file ensures backward compatibility while we transition to the new architecture
///
/// @deprecated Import ContentFacadeService directly for new code
/// @deprecated Import LegacyContentService directly if you need the legacy implementation

// Import and export the legacy service
import 'legacy_content_service.dart';
export 'legacy_content_service.dart';

// Re-export as ContentService for existing imports
@Deprecated('Use ContentFacadeService for new code')
typedef ContentService = LegacyContentService;
