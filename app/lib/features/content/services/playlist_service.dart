import 'package:flutter/foundation.dart';

import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/models/playlist.dart';

/// Service for managing audio playlists and playback queues.
///
/// Handles creation, modification, and navigation of playlists.
class PlaylistService extends ChangeNotifier {
  // State
  Playlist? _currentPlaylist;
  List<AudioFile> _queue = [];
  bool _shuffleEnabled = false;
  List<AudioFile> _originalQueue = []; // Backup for un-shuffling

  // Getters
  Playlist? get currentPlaylist => _currentPlaylist;
  List<AudioFile> get queue => _queue;
  bool get hasPlaylist => _currentPlaylist != null;
  bool get hasQueue => _queue.isNotEmpty;
  bool get isShuffleEnabled => _shuffleEnabled;
  String? get playlistName => _currentPlaylist?.name;

  /// Set the current queue of episodes
  void setQueue(List<AudioFile> episodes, {String? name}) {
    _queue = List.from(episodes);
    _originalQueue = List.from(episodes);

    if (name != null) {
      _currentPlaylist = Playlist.fromEpisodes(name, episodes);
    } else {
      _currentPlaylist = null;
    }

    if (_shuffleEnabled) {
      _reshuffleQueue();
    }

    notifyListeners();
  }

  /// Create a new playlist
  void createPlaylist(String name, List<AudioFile> episodes) {
    _currentPlaylist = Playlist.fromEpisodes(name, episodes);
    _queue = List.from(episodes);
    _originalQueue = List.from(episodes);
    notifyListeners();
  }

  /// Add an episode to the current playlist/queue
  void addToPlaylist(AudioFile episode) {
    if (_currentPlaylist == null) {
      createPlaylist('My Playlist', [episode]);
    } else {
      _currentPlaylist = _currentPlaylist!.addEpisode(episode);
      _queue.add(episode);
      _originalQueue.add(episode);
      notifyListeners();
    }
  }

  /// Remove an episode from the current playlist
  void removeFromPlaylist(AudioFile episode) {
    if (_currentPlaylist != null) {
      _currentPlaylist = _currentPlaylist!.removeEpisode(episode);
      _queue.removeWhere((e) => e.id == episode.id);
      _originalQueue.removeWhere((e) => e.id == episode.id);
      notifyListeners();
    }
  }

  /// Clear the current playlist and queue
  void clearPlaylist() {
    _currentPlaylist = null;
    _queue.clear();
    _originalQueue.clear();
    notifyListeners();
  }

  /// Toggle shuffle mode
  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    if (_shuffleEnabled) {
      _reshuffleQueue();
    } else {
      _queue = List.from(_originalQueue);
    }
    notifyListeners();
  }

  void _reshuffleQueue() {
    // Keep current playing item? Complex. For now just shuffle all.
    _queue.shuffle();
  }

  /// Get the next episode in the queue
  AudioFile? getNextEpisode(AudioFile currentEpisode) {
    final currentIndex = _queue.indexWhere((e) => e.id == currentEpisode.id);
    if (currentIndex >= 0 && currentIndex < _queue.length - 1) {
      return _queue[currentIndex + 1];
    }
    return null;
  }

  /// Get the previous episode in the queue
  AudioFile? getPreviousEpisode(AudioFile currentEpisode) {
    final currentIndex = _queue.indexWhere((e) => e.id == currentEpisode.id);
    if (currentIndex > 0) {
      return _queue[currentIndex - 1];
    }
    return null;
  }

  /// Get debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasPlaylist': hasPlaylist,
      'playlistName': playlistName,
      'queueSize': _queue.length,
      'shuffleEnabled': _shuffleEnabled,
    };
  }
}
