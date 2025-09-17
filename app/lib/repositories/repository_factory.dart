import 'episode_repository.dart';
import 'episode_repository_impl.dart';
import 'content_repository.dart';
import 'progress_repository.dart';
import 'preferences_repository.dart';
import '../services/cache_service.dart';
import '../services/progress_tracking_service.dart';
import '../services/user_preferences_service.dart';

/// Factory for creating and managing repository instances
/// Provides a centralized way to access all repositories with proper dependency injection
class RepositoryFactory {
  static RepositoryFactory? _instance;
  static RepositoryFactory get instance =>
      _instance ??= RepositoryFactory._internal();

  RepositoryFactory._internal();

  // Repository instances
  EpisodeRepository? _episodeRepository;
  ContentRepository? _contentRepository;
  ProgressRepository? _progressRepository;
  PreferencesRepository? _preferencesRepository;

  /// Get episode repository instance
  EpisodeRepository get episodeRepository {
    return _episodeRepository ??= EpisodeRepositoryImpl();
  }

  /// Get content repository instance (implemented by CacheService)
  ContentRepository get contentRepository {
    return _contentRepository ??= CacheService();
  }

  /// Get progress repository instance (implemented by ProgressTrackingService)
  ProgressRepository get progressRepository {
    return _progressRepository ??= ProgressTrackingService();
  }

  /// Get preferences repository instance (implemented by UserPreferencesService)
  PreferencesRepository get preferencesRepository {
    return _preferencesRepository ??= UserPreferencesService();
  }

  /// Initialize all repositories
  Future<void> initializeRepositories() async {
    await progressRepository.initialize();
    await preferencesRepository.initialize();
  }

  /// Dispose all repositories
  void dispose() {
    _episodeRepository?.dispose();
    _contentRepository?.dispose();
    _progressRepository?.dispose();
    _preferencesRepository?.dispose();

    _episodeRepository = null;
    _contentRepository = null;
    _progressRepository = null;
    _preferencesRepository = null;
  }

  /// Reset factory instance (for testing)
  static void reset() {
    if (_instance != null) {
      _instance!.dispose();
      _instance = null;
    }
  }

  /// Set custom repository implementations (for testing)
  void setRepositoriesForTesting({
    EpisodeRepository? episodeRepository,
    ContentRepository? contentRepository,
    ProgressRepository? progressRepository,
    PreferencesRepository? preferencesRepository,
  }) {
    _episodeRepository = episodeRepository;
    _contentRepository = contentRepository;
    _progressRepository = progressRepository;
    _preferencesRepository = preferencesRepository;
  }
}
