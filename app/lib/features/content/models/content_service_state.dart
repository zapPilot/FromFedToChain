import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

/// State class for content service to enable granular rebuilds
class ContentServiceState {
  final List<AudioFile> allEpisodes;
  final List<AudioFile> filteredEpisodes;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String selectedLanguage;
  final String selectedCategory;
  final String searchQuery;

  const ContentServiceState({
    required this.allEpisodes,
    required this.filteredEpisodes,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.selectedLanguage,
    required this.selectedCategory,
    required this.searchQuery,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentServiceState &&
          runtimeType == other.runtimeType &&
          allEpisodes.length == other.allEpisodes.length &&
          filteredEpisodes.length == other.filteredEpisodes.length &&
          isLoading == other.isLoading &&
          hasError == other.hasError &&
          errorMessage == other.errorMessage &&
          selectedLanguage == other.selectedLanguage &&
          selectedCategory == other.selectedCategory &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode =>
      allEpisodes.length.hashCode ^
      filteredEpisodes.length.hashCode ^
      isLoading.hashCode ^
      hasError.hashCode ^
      errorMessage.hashCode ^
      selectedLanguage.hashCode ^
      selectedCategory.hashCode ^
      searchQuery.hashCode;
}
