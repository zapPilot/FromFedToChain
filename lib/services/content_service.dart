import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/audio_content.dart';
import '../models/audio_file.dart';
import 'streaming_api_service.dart';

class ContentService extends ChangeNotifier {
  static const String contentDir = 'content';
  static const String audioDir = 'audio';
  
  List<AudioContent> _contents = [];
  List<AudioFile> _audioFiles = [];
  bool _isLoading = false;
  String? _error;
  bool _useApiData = kIsWeb ? true : true; // Force API on web, default to API on all platforms
  
  // Filters
  String? _selectedLanguage;
  String? _selectedCategory;
  String _searchQuery = '';

  // Getters
  List<AudioContent> get contents => _filteredContents;
  List<AudioFile> get audioFiles => _filteredAudioFiles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedLanguage => _selectedLanguage;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // Available options
  List<String> get availableLanguages {
    final languages = _contents.map((c) => c.language).toSet().toList();
    languages.sort();
    return languages;
  }

  List<String> get availableCategories {
    final categories = _contents.map((c) => c.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Filtered data
  List<AudioContent> get _filteredContents {
    var filtered = _contents.where((content) {
      // Language filter
      if (_selectedLanguage != null && content.language != _selectedLanguage) {
        return false;
      }
      
      // Category filter
      if (_selectedCategory != null && content.category != _selectedCategory) {
        return false;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return content.title.toLowerCase().contains(query) ||
               content.content.toLowerCase().contains(query) ||
               content.id.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
    
    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  List<AudioFile> get _filteredAudioFiles {
    var filtered = _audioFiles.where((audioFile) {
      // Language filter
      if (_selectedLanguage != null && audioFile.language != _selectedLanguage) {
        return false;
      }
      
      // Category filter
      if (_selectedCategory != null && audioFile.category != _selectedCategory) {
        return false;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return audioFile.id.toLowerCase().contains(query) ||
               audioFile.fileName.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
    
    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.created.compareTo(a.created));
    return filtered;
  }

  // Load all content and audio files
  Future<void> loadContent() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_useApiData || kIsWeb) {
        // Always use API on web platform
        await _loadDataFromApi();
      } else {
        // Local file loading only on non-web platforms
        await Future.wait([
          _loadContentFiles(),
          _loadAudioFiles(),
        ]);
      }
    } catch (e) {
      _error = 'Failed to load content: $e';
      print('ContentService error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load data from streaming API
  Future<void> _loadDataFromApi() async {
    try {
      // Get all episodes from the API
      final episodesData = await StreamingApiService.getAllEpisodes();
      
      final audioFiles = <AudioFile>[];
      
      // Convert API response to AudioFile objects
      for (final episodeData in episodesData) {
        try {
          final language = episodeData['language'] as String;
          final category = episodeData['category'] as String;
          
          final audioFile = AudioFile.fromApiResponse(
            episodeData,
            language,
            category,
          );
          
          audioFiles.add(audioFile);
        } catch (e) {
          if (kDebugMode) {
            print('Error processing episode data: $episodeData, Error: $e');
          }
        }
      }
      
      _audioFiles = audioFiles;
      
      // For now, we'll create minimal content objects from audio files
      // In the future, this could be enhanced to fetch actual content metadata
      _contents = audioFiles.map((audioFile) => AudioContent(
        id: audioFile.id,
        status: 'published', // Assume published if available via API
        category: audioFile.category,
        date: audioFile.displayDate,
        language: audioFile.language,
        title: _generateTitleFromId(audioFile.id),
        content: 'Content from streaming service', // Placeholder
        references: [],
        audioFile: audioFile.fileName,
        socialHook: null,
        updatedAt: DateTime.now(),
      )).toList();
      
    } catch (e) {
      throw Exception('Failed to load data from API: $e');
    }
  }

  // Helper method to generate a readable title from episode ID
  String _generateTitleFromId(String id) {
    // Convert ID like "2025-07-03-crypto-startup-frameworks" to "Crypto Startup Frameworks"
    final parts = id.split('-');
    if (parts.length > 3) {
      // Skip date parts (first 3) and capitalize words
      return parts.skip(3).map((word) => 
        word[0].toUpperCase() + word.substring(1)
      ).join(' ');
    }
    return id; // Fallback to original ID
  }

  // Load content files from the content directory
  Future<void> _loadContentFiles() async {
    // Skip local file loading on web platform
    if (kIsWeb) {
      _contents = [];
      return;
    }

    // Local file loading is not available on web
    // This method should only be called on mobile platforms
    _contents = [];
    
    if (kDebugMode) {
      print('Local content file loading not implemented for mobile platform');
    }
  }

  // Load audio files from the audio directory
  Future<void> _loadAudioFiles() async {
    // Skip local file loading on web platform
    if (kIsWeb) {
      _audioFiles = [];
      return;
    }

    // Local file loading is not available on web
    // This method should only be called on mobile platforms
    _audioFiles = [];
    
    if (kDebugMode) {
      print('Local audio file loading not implemented for mobile platform');
    }
  }

  // Filter methods
  void setLanguageFilter(String? language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedLanguage = null;
    _selectedCategory = null;
    _searchQuery = '';
    notifyListeners();
  }

  // Get content by ID and language
  AudioContent? getContent(String id, String language) {
    try {
      return _contents.firstWhere(
        (content) => content.id == id && content.language == language,
      );
    } catch (e) {
      return null;
    }
  }

  // Get audio file by ID and language
  AudioFile? getAudioFile(String id, String language) {
    try {
      return _audioFiles.firstWhere(
        (audioFile) => audioFile.id == id && audioFile.language == language,
      );
    } catch (e) {
      return null;
    }
  }

  // Get content with matching audio file
  List<AudioContent> get contentsWithAudio {
    return _contents.where((content) {
      return _audioFiles.any((audioFile) => 
        audioFile.id == content.id && audioFile.language == content.language);
    }).toList();
  }

  // Toggle between API and local data
  void setUseApiData(bool useApi) {
    if (_useApiData != useApi) {
      _useApiData = useApi;
      // Clear current data and reload
      _contents.clear();
      _audioFiles.clear();
      loadContent();
    }
  }

  // Get current data source
  bool get isUsingApiData => _useApiData;
}