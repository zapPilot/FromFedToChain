import 'package:flutter/foundation.dart';
import '../models/audio_file.dart';
import '../models/playlist.dart';

/// Service for managing playlists and episode navigation
/// Handles playlist creation, episode addition/removal, and playback navigation
class PlaylistService extends ChangeNotifier {
  Playlist? _currentPlaylist;

  // Getters
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get hasCurrentPlaylist => _currentPlaylist != null;
  List<AudioFile> get currentPlaylistEpisodes =>
      _currentPlaylist?.episodes ?? [];

  /// Create playlist from specific episodes
  void createPlaylist(String name, List<AudioFile> episodes) {
    _currentPlaylist = Playlist.fromEpisodes(name, episodes);
    notifyListeners();

    if (kDebugMode) {
      print(
          'PlaylistService: Created playlist "$name" with ${episodes.length} episodes');
    }
  }

  /// Create playlist from filtered episodes
  void createPlaylistFromFiltered(
      String? name, List<AudioFile> filteredEpisodes) {
    final playlistName = name ?? 'Current Selection';
    _currentPlaylist = Playlist.fromEpisodes(playlistName, filteredEpisodes);
    notifyListeners();

    if (kDebugMode) {
      print(
          'PlaylistService: Created playlist "$playlistName" from ${filteredEpisodes.length} filtered episodes');
    }
  }

  /// Add episode to current playlist
  void addToCurrentPlaylist(AudioFile episode) {
    if (_currentPlaylist == null) {
      createPlaylist('My Playlist', [episode]);
    } else {
      _currentPlaylist = _currentPlaylist!.addEpisode(episode);
      notifyListeners();
    }

    if (kDebugMode) {
      print(
          'PlaylistService: Added episode "${episode.title}" to current playlist');
    }
  }

  /// Remove episode from current playlist
  void removeFromCurrentPlaylist(AudioFile episode) {
    if (_currentPlaylist != null) {
      _currentPlaylist = _currentPlaylist!.removeEpisode(episode);
      notifyListeners();

      if (kDebugMode) {
        print(
            'PlaylistService: Removed episode "${episode.title}" from current playlist');
      }
    }
  }

  /// Get next episode for playback
  /// Returns next episode in playlist if current episode is in playlist,
  /// otherwise falls back to filtered episodes navigation
  AudioFile? getNextEpisode(
      AudioFile currentEpisode, List<AudioFile> filteredEpisodes) {
    // If we have a current playlist, use playlist navigation
    if (_currentPlaylist != null) {
      final currentInPlaylist = _currentPlaylist!.episodes
          .any((episode) => episode.id == currentEpisode.id);

      if (currentInPlaylist) {
        final currentPlaylist = _currentPlaylist!.moveToEpisode(currentEpisode);
        return currentPlaylist.nextEpisode;
      }
    }

    // Fallback to filtered episodes navigation
    final currentIndex = filteredEpisodes
        .indexWhere((episode) => episode.id == currentEpisode.id);

    if (currentIndex >= 0 && currentIndex < filteredEpisodes.length - 1) {
      return filteredEpisodes[currentIndex + 1];
    }

    return null;
  }

  /// Get previous episode for playback
  /// Returns previous episode in playlist if current episode is in playlist,
  /// otherwise falls back to filtered episodes navigation
  AudioFile? getPreviousEpisode(
      AudioFile currentEpisode, List<AudioFile> filteredEpisodes) {
    // If we have a current playlist, use playlist navigation
    if (_currentPlaylist != null) {
      final currentInPlaylist = _currentPlaylist!.episodes
          .any((episode) => episode.id == currentEpisode.id);

      if (currentInPlaylist) {
        final currentPlaylist = _currentPlaylist!.moveToEpisode(currentEpisode);
        return currentPlaylist.previousEpisode;
      }
    }

    // Fallback to filtered episodes navigation
    final currentIndex = filteredEpisodes
        .indexWhere((episode) => episode.id == currentEpisode.id);

    if (currentIndex > 0) {
      return filteredEpisodes[currentIndex - 1];
    }

    return null;
  }

  /// Check if episode is in current playlist
  bool isEpisodeInCurrentPlaylist(AudioFile episode) {
    if (_currentPlaylist == null) return false;
    return _currentPlaylist!.episodes.any((e) => e.id == episode.id);
  }

  /// Get current playlist position for an episode
  int? getCurrentPlaylistPosition(AudioFile episode) {
    if (_currentPlaylist == null) return null;

    final index =
        _currentPlaylist!.episodes.indexWhere((e) => e.id == episode.id);
    return index >= 0 ? index : null;
  }

  /// Move to specific episode in current playlist
  void moveToEpisodeInPlaylist(AudioFile episode) {
    if (_currentPlaylist != null && isEpisodeInCurrentPlaylist(episode)) {
      _currentPlaylist = _currentPlaylist!.moveToEpisode(episode);
      notifyListeners();

      if (kDebugMode) {
        print(
            'PlaylistService: Moved to episode "${episode.title}" in playlist');
      }
    }
  }

  /// Shuffle current playlist
  void shuffleCurrentPlaylist() {
    if (_currentPlaylist != null) {
      final shuffledEpisodes = List<AudioFile>.from(_currentPlaylist!.episodes);
      shuffledEpisodes.shuffle();

      _currentPlaylist = _currentPlaylist!.copyWith(
        episodes: shuffledEpisodes,
        shuffleEnabled: true,
        currentIndex: 0, // Reset to start of shuffled playlist
        updatedAt: DateTime.now(),
      );
      notifyListeners();

      if (kDebugMode) {
        print('PlaylistService: Shuffled current playlist');
      }
    }
  }

  /// Clear current playlist
  void clearCurrentPlaylist() {
    _currentPlaylist = null;
    notifyListeners();

    if (kDebugMode) {
      print('PlaylistService: Cleared current playlist');
    }
  }

  /// Get playlist statistics
  Map<String, dynamic> getPlaylistStatistics() {
    if (_currentPlaylist == null) {
      return {
        'hasPlaylist': false,
        'episodeCount': 0,
        'totalDuration': Duration.zero,
      };
    }

    final episodes = _currentPlaylist!.episodes;
    final totalDuration = episodes.fold<Duration>(
      Duration.zero,
      (sum, episode) => sum + (episode.duration ?? Duration.zero),
    );

    return {
      'hasPlaylist': true,
      'name': _currentPlaylist!.name,
      'episodeCount': episodes.length,
      'totalDuration': totalDuration,
      'currentEpisodeIndex': _currentPlaylist!.currentIndex,
      'languages': _getLanguageStats(episodes),
      'categories': _getCategoryStats(episodes),
    };
  }

  /// Get language distribution in current playlist
  Map<String, int> _getLanguageStats(List<AudioFile> episodes) {
    final stats = <String, int>{};
    for (final episode in episodes) {
      stats[episode.language] = (stats[episode.language] ?? 0) + 1;
    }
    return stats;
  }

  /// Get category distribution in current playlist
  Map<String, int> _getCategoryStats(List<AudioFile> episodes) {
    final stats = <String, int>{};
    for (final episode in episodes) {
      stats[episode.category] = (stats[episode.category] ?? 0) + 1;
    }
    return stats;
  }

  /// Create playlist from recently listened episodes
  void createPlaylistFromHistory(List<AudioFile> historyEpisodes,
      {String? name}) {
    final playlistName = name ?? 'Recently Listened';
    createPlaylist(playlistName, historyEpisodes);
  }

  /// Create playlist from unfinished episodes
  void createPlaylistFromUnfinished(List<AudioFile> unfinishedEpisodes,
      {String? name}) {
    final playlistName = name ?? 'Continue Listening';
    createPlaylist(playlistName, unfinishedEpisodes);
  }

  /// Export current playlist as a simple map (for sharing/saving)
  Map<String, dynamic>? exportCurrentPlaylist() {
    if (_currentPlaylist == null) return null;

    return {
      'name': _currentPlaylist!.name,
      'episodeIds': _currentPlaylist!.episodes.map((e) => e.id).toList(),
      'currentIndex': _currentPlaylist!.currentIndex,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import playlist from exported data
  void importPlaylist(
      Map<String, dynamic> playlistData, List<AudioFile> availableEpisodes) {
    final name = playlistData['name'] as String? ?? 'Imported Playlist';
    final episodeIds =
        (playlistData['episodeIds'] as List?)?.cast<String>() ?? [];

    // Find episodes that exist in available episodes
    final episodes = <AudioFile>[];
    for (final id in episodeIds) {
      try {
        final episode = availableEpisodes.firstWhere((e) => e.id == id);
        episodes.add(episode);
      } catch (e) {
        if (kDebugMode) {
          print(
              'PlaylistService: Episode with ID "$id" not found during import');
        }
      }
    }

    if (episodes.isNotEmpty) {
      createPlaylist(name, episodes);

      // Restore current index if provided
      final currentIndex = playlistData['currentIndex'] as int?;
      if (currentIndex != null && currentIndex < episodes.length) {
        _currentPlaylist =
            _currentPlaylist!.copyWith(currentIndex: currentIndex);
        notifyListeners();
      }

      if (kDebugMode) {
        print(
            'PlaylistService: Imported playlist "$name" with ${episodes.length} episodes');
      }
    }
  }

  @override
  void dispose() {
    _currentPlaylist = null;
    super.dispose();
  }

  // Testing methods
  @visibleForTesting
  void setCurrentPlaylistForTesting(Playlist? playlist) {
    _currentPlaylist = playlist;
    notifyListeners();
  }
}
