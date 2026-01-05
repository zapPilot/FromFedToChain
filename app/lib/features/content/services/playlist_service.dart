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
  /// The currently active playlist object.
  Playlist? get currentPlaylist => _currentPlaylist;

  /// The current list of episodes in the queue.
  List<AudioFile> get queue => _queue;

  /// Whether a playlist is currently active.
  bool get hasPlaylist => _currentPlaylist != null;

  /// Whether there are any episodes in the queue.
  bool get hasQueue => _queue.isNotEmpty;

  /// Whether shuffle mode is enabled.
  bool get isShuffleEnabled => _shuffleEnabled;

  /// The name of the current playlist, if any.
  String? get playlistName => _currentPlaylist?.name;

  /// Sets the current playback queue to a list of [episodes].
  ///
  /// Optionally provides a [name] for the playlist. If [name] is provided,
  /// a new [Playlist] object is created.
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

  /// Creates a new playlist with the given [name] and [episodes].
  ///
  /// This also sets the current queue to the provided episodes.
  void createPlaylist(String name, List<AudioFile> episodes) {
    _currentPlaylist = Playlist.fromEpisodes(name, episodes);
    _queue = List.from(episodes);
    _originalQueue = List.from(episodes);
    notifyListeners();
  }

  /// Adds an [episode] to the current playlist and queue.
  ///
  /// If no playlist exists, creates a new one named 'My Playlist'.
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

  /// Removes an [episode] from the current playlist and queue.
  void removeFromPlaylist(AudioFile episode) {
    if (_currentPlaylist != null) {
      _currentPlaylist = _currentPlaylist!.removeEpisode(episode);
      _queue.removeWhere((e) => e.id == episode.id);
      _originalQueue.removeWhere((e) => e.id == episode.id);
      notifyListeners();
    }
  }

  /// Clears the current playlist and queue.
  void clearPlaylist() {
    _currentPlaylist = null;
    _queue.clear();
    _originalQueue.clear();
    notifyListeners();
  }

  /// Toggles the shuffle mode state.
  ///
  /// If enabled, reshuffles the current queue. If disabled, restores the original order.
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

  /// Returns the next episode in the queue relative to [currentEpisode].
  ///
  /// Returns null if [currentEpisode] is the last item or not found.
  AudioFile? getNextEpisode(AudioFile currentEpisode) {
    final currentIndex = _queue.indexWhere((e) => e.id == currentEpisode.id);
    if (currentIndex >= 0 && currentIndex < _queue.length - 1) {
      return _queue[currentIndex + 1];
    }
    return null;
  }

  /// Returns the previous episode in the queue relative to [currentEpisode].
  ///
  /// Returns null if [currentEpisode] is the first item or not found.
  AudioFile? getPreviousEpisode(AudioFile currentEpisode) {
    final currentIndex = _queue.indexWhere((e) => e.id == currentEpisode.id);
    if (currentIndex > 0) {
      return _queue[currentIndex - 1];
    }
    return null;
  }

  /// Returns debug information about the internal state.
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasPlaylist': hasPlaylist,
      'playlistName': playlistName,
      'queueSize': _queue.length,
      'shuffleEnabled': _shuffleEnabled,
    };
  }
}
