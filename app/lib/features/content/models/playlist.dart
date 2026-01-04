import 'package:equatable/equatable.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/core/utils/duration_utils.dart';

/// Represents a playlist of audio files with playback management
class Playlist extends Equatable {
  final String id;
  final String name;
  final List<AudioFile> episodes;
  final int currentIndex;
  final bool shuffleEnabled;
  final PlaylistRepeatMode repeatMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Playlist({
    required this.id,
    required this.name,
    required this.episodes,
    this.currentIndex = 0,
    this.shuffleEnabled = false,
    this.repeatMode = PlaylistRepeatMode.none,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty playlist
  factory Playlist.empty(String name) {
    final now = DateTime.now();
    return Playlist(
      id: 'playlist_${now.millisecondsSinceEpoch}',
      name: name,
      episodes: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create playlist from episodes
  factory Playlist.fromEpisodes(String name, List<AudioFile> episodes) {
    final now = DateTime.now();
    return Playlist(
      id: 'playlist_${now.millisecondsSinceEpoch}',
      name: name,
      episodes: episodes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from JSON
  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      episodes: (json['episodes'] as List)
          .map((episodeJson) => AudioFile.fromApiResponse(episodeJson))
          .toList(),
      currentIndex: json['current_index'] as int? ?? 0,
      shuffleEnabled: json['shuffle_enabled'] as bool? ?? false,
      repeatMode: PlaylistRepeatMode.fromString(
          json['repeat_mode'] as String? ?? 'none'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'episodes': episodes.map((episode) => episode.toJson()).toList(),
      'current_index': currentIndex,
      'shuffle_enabled': shuffleEnabled,
      'repeat_mode': repeatMode.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Playlist copyWith({
    String? id,
    String? name,
    List<AudioFile>? episodes,
    int? currentIndex,
    bool? shuffleEnabled,
    PlaylistRepeatMode? repeatMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      episodes: episodes ?? this.episodes,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get current episode
  AudioFile? get currentEpisode {
    if (episodes.isEmpty ||
        currentIndex < 0 ||
        currentIndex >= episodes.length) {
      return null;
    }
    return episodes[currentIndex];
  }

  /// Get next episode
  AudioFile? get nextEpisode {
    if (episodes.isEmpty) return null;

    switch (repeatMode) {
      case PlaylistRepeatMode.none:
        final nextIndex = currentIndex + 1;
        return nextIndex < episodes.length ? episodes[nextIndex] : null;

      case PlaylistRepeatMode.playlist:
        final nextIndex = (currentIndex + 1) % episodes.length;
        return episodes[nextIndex];

      case PlaylistRepeatMode.single:
        return currentEpisode;
    }
  }

  /// Get previous episode
  AudioFile? get previousEpisode {
    if (episodes.isEmpty) return null;

    switch (repeatMode) {
      case PlaylistRepeatMode.none:
        final prevIndex = currentIndex - 1;
        return prevIndex >= 0 ? episodes[prevIndex] : null;

      case PlaylistRepeatMode.playlist:
        final prevIndex = currentIndex - 1;
        return episodes[prevIndex < 0 ? episodes.length - 1 : prevIndex];

      case PlaylistRepeatMode.single:
        return currentEpisode;
    }
  }

  /// Check if playlist is empty
  bool get isEmpty => episodes.isEmpty;

  /// Check if playlist is not empty
  bool get isNotEmpty => episodes.isNotEmpty;

  /// Get total duration of all episodes
  Duration get totalDuration {
    return episodes.fold(Duration.zero, (total, episode) {
      return total + (episode.duration ?? Duration.zero);
    });
  }

  /// Get formatted total duration
  String get formattedTotalDuration {
    return DurationUtils.formatDurationText(totalDuration);
  }

  /// Get episode count
  int get episodeCount => episodes.length;

  /// Add episode to playlist
  Playlist addEpisode(AudioFile episode) {
    final newEpisodes = List<AudioFile>.from(episodes)..add(episode);
    return copyWith(
      episodes: newEpisodes,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove episode from playlist
  Playlist removeEpisode(AudioFile episode) {
    final newEpisodes = episodes.where((e) => e.id != episode.id).toList();
    int newCurrentIndex = currentIndex;

    // Adjust current index if needed
    if (currentIndex >= newEpisodes.length) {
      newCurrentIndex = newEpisodes.length - 1;
    }

    return copyWith(
      episodes: newEpisodes,
      currentIndex: newCurrentIndex,
      updatedAt: DateTime.now(),
    );
  }

  /// Move to specific episode
  Playlist moveToEpisode(AudioFile episode) {
    final index = episodes.indexWhere((e) => e.id == episode.id);
    if (index == -1) return this;

    return copyWith(
      currentIndex: index,
      updatedAt: DateTime.now(),
    );
  }

  /// Move to next episode
  Playlist moveToNext() {
    if (isEmpty) return this;

    int newIndex;
    switch (repeatMode) {
      case PlaylistRepeatMode.none:
        newIndex = currentIndex + 1;
        if (newIndex >= episodes.length) return this; // Stay at current
        break;

      case PlaylistRepeatMode.playlist:
        newIndex = (currentIndex + 1) % episodes.length;
        break;

      case PlaylistRepeatMode.single:
        newIndex = currentIndex; // Stay at current
        break;
    }

    return copyWith(
      currentIndex: newIndex,
      updatedAt: DateTime.now(),
    );
  }

  /// Move to previous episode
  Playlist moveToPrevious() {
    if (isEmpty) return this;

    int newIndex;
    switch (repeatMode) {
      case PlaylistRepeatMode.none:
        newIndex = currentIndex - 1;
        if (newIndex < 0) return this; // Stay at current
        break;

      case PlaylistRepeatMode.playlist:
        newIndex = currentIndex - 1;
        if (newIndex < 0) newIndex = episodes.length - 1;
        break;

      case PlaylistRepeatMode.single:
        newIndex = currentIndex; // Stay at current
        break;
    }

    return copyWith(
      currentIndex: newIndex,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle shuffle mode
  Playlist toggleShuffle() {
    return copyWith(
      shuffleEnabled: !shuffleEnabled,
      updatedAt: DateTime.now(),
    );
  }

  /// Set repeat mode
  Playlist setRepeatMode(PlaylistRepeatMode mode) {
    return copyWith(
      repeatMode: mode,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        episodes,
        currentIndex,
        shuffleEnabled,
        repeatMode,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Playlist(id: $id, name: $name, episodes: ${episodes.length}, currentIndex: $currentIndex)';
  }
}

/// Playlist repeat modes
enum PlaylistRepeatMode {
  none,
  playlist,
  single;

  factory PlaylistRepeatMode.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'playlist':
        return PlaylistRepeatMode.playlist;
      case 'single':
        return PlaylistRepeatMode.single;
      default:
        return PlaylistRepeatMode.none;
    }
  }

  @override
  String toString() {
    switch (this) {
      case PlaylistRepeatMode.none:
        return 'none';
      case PlaylistRepeatMode.playlist:
        return 'playlist';
      case PlaylistRepeatMode.single:
        return 'single';
    }
  }

  String get displayName {
    switch (this) {
      case PlaylistRepeatMode.none:
        return 'No Repeat';
      case PlaylistRepeatMode.playlist:
        return 'Repeat All';
      case PlaylistRepeatMode.single:
        return 'Repeat One';
    }
  }

  String get icon {
    switch (this) {
      case PlaylistRepeatMode.none:
        return '🔁';
      case PlaylistRepeatMode.playlist:
        return '🔂';
      case PlaylistRepeatMode.single:
        return '🔂';
    }
  }
}
