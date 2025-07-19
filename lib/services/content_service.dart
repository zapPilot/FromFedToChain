import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/audio_content.dart';
import '../models/audio_file.dart';
import '../config/api_config.dart';
import 'streaming_api_service.dart';
import 'language_service.dart';

class ContentService extends ChangeNotifier {
  static const String contentDir = 'content';
  static const String audioDir = 'audio';
  
  final LanguageService? _languageService;
  
  List<AudioContent> _contents = [];
  List<AudioFile> _audioFiles = [];
  bool _isLoading = false;
  String? _error;
  bool _useApiData = kIsWeb ? true : true; // Force API on web, default to API on all platforms
  
  // Filters
  String? _selectedLanguage;
  String? _selectedCategory;
  String _searchQuery = '';
  
  ContentService([this._languageService]) {
    // Listen to language changes
    _languageService?.addListener(_onLanguageChanged);
  }
  
  @override
  void dispose() {
    _languageService?.removeListener(_onLanguageChanged);
    super.dispose();
  }
  
  void _onLanguageChanged() {
    // Update content filtering when language changes
    notifyListeners();
  }

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
      // Language filter - use LanguageService preference if available
      final effectiveLanguage = _languageService?.currentLanguage ?? _selectedLanguage;
      if (effectiveLanguage != null && content.language != effectiveLanguage) {
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
      // Language filter - use LanguageService preference if available
      final effectiveLanguage = _languageService?.currentLanguage ?? _selectedLanguage;
      if (effectiveLanguage != null && audioFile.language != effectiveLanguage) {
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
      final errorMessage = e.toString();
      if (errorMessage.contains('CORS') || errorMessage.contains('connectivity')) {
        _error = 'Network Error: Cannot connect to API. This may be a CORS issue in development.\n\nTry running: flutter run -d chrome --web-browser-flag="--disable-web-security"';
      } else {
        _error = 'Failed to load content: $errorMessage';
      }
      print('ContentService error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load data from streaming API
  Future<void> _loadDataFromApi() async {
    try {
      print('ContentService: Starting API data load...');
      
      // Test connectivity first
      print('ContentService: Testing API connectivity...');
      final isConnected = await StreamingApiService.testConnectivity();
      if (!isConnected) {
        throw Exception('API connectivity test failed - check CORS and network connection');
      }
      print('ContentService: API connectivity test passed');
      
      // Get all episodes from the API
      print('ContentService: Fetching all episodes...');
      final episodesData = await StreamingApiService.getAllEpisodes();
      print('ContentService: Received ${episodesData.length} episodes from API');
      
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
      
      print('ContentService: Processed ${audioFiles.length} audio files');
      _audioFiles = audioFiles;
      
      // Create content objects from audio files with enhanced metadata
      _contents = audioFiles.map((audioFile) => AudioContent(
        id: audioFile.id,
        status: 'published', // Assume published if available via API
        category: audioFile.category,
        date: audioFile.displayDate,
        language: audioFile.language,
        title: audioFile.displayTitle, // Use the enhanced display title from AudioFile
        content: 'Content from streaming service', // Placeholder
        references: [],
        audioFile: audioFile.fileName,
        socialHook: null,
        updatedAt: DateTime.now(),
        author: 'David Chang', // Hardcoded author for all episodes
      )).toList();
      
      print('ContentService: API data load completed successfully');
    } catch (e) {
      print('ContentService: API load failed: $e');
      throw Exception('Failed to load data from API: $e');
    }
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

  // Fetch individual content by ID from API
  Future<AudioContent?> fetchContentById(String id, String language, String category) async {
    try {
      if (kDebugMode) {
        print('ContentService: Fetching content for $id ($language/$category)');
      }
      
      final url = Uri.parse('${ApiConfig.streamingBaseUrl}/api/content/$language/$category/$id');
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(ApiConfig.apiTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final content = AudioContent.fromJson(jsonData);
        
        // Update the cached content list
        final existingIndex = _contents.indexWhere(
          (c) => c.id == id && c.language == language,
        );
        
        if (existingIndex >= 0) {
          _contents[existingIndex] = content;
        } else {
          _contents.add(content);
        }
        
        notifyListeners();
        
        if (kDebugMode) {
          print('ContentService: Successfully fetched content for $id');
        }
        
        return content;
      } else {
        if (kDebugMode) {
          print('ContentService: Failed to fetch content - HTTP ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ContentService: Error fetching content for $id: $e');
      }
      return null;
    }
  }

  // Get content with lazy loading - fetches from API if not already loaded
  Future<AudioContent?> getContentWithFetch(String id, String language, String category) async {
    // First try to get from cache
    final cachedContent = getContent(id, language);
    
    // If we have real content (not placeholder), return it
    if (cachedContent != null && cachedContent.content != 'Content from streaming service') {
      return cachedContent;
    }
    
    // Otherwise, fetch from API
    return await fetchContentById(id, language, category);
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

  // Get audio files by language for language switching
  Future<List<AudioFile>> getAudioFilesByLanguage(String language) async {
    return _audioFiles.where((audioFile) => audioFile.language == language).toList();
  }

  // Get episode navigation methods for lock screen controls
  AudioFile? getNextEpisode(AudioFile currentEpisode) {
    final currentLanguageFiles = _audioFiles
        .where((file) => file.language == currentEpisode.language)
        .toList();
    
    // Sort by creation date (newest first, same as _filteredAudioFiles)
    currentLanguageFiles.sort((a, b) => b.created.compareTo(a.created));
    
    final currentIndex = currentLanguageFiles.indexWhere((file) => file.id == currentEpisode.id);
    
    if (currentIndex >= 0 && currentIndex < currentLanguageFiles.length - 1) {
      return currentLanguageFiles[currentIndex + 1]; // Next episode (older)
    }
    
    return null; // No next episode
  }

  AudioFile? getPreviousEpisode(AudioFile currentEpisode) {
    final currentLanguageFiles = _audioFiles
        .where((file) => file.language == currentEpisode.language)
        .toList();
    
    // Sort by creation date (newest first, same as _filteredAudioFiles)
    currentLanguageFiles.sort((a, b) => b.created.compareTo(a.created));
    
    final currentIndex = currentLanguageFiles.indexWhere((file) => file.id == currentEpisode.id);
    
    if (currentIndex > 0) {
      return currentLanguageFiles[currentIndex - 1]; // Previous episode (newer)
    }
    
    return null; // No previous episode
  }

  // Get all episodes for the current language in proper order for queue management
  List<AudioFile> getCurrentLanguageEpisodes() {
    final effectiveLanguage = _languageService?.currentLanguage ?? _selectedLanguage;
    if (effectiveLanguage == null) return [];
    
    final currentLanguageFiles = _audioFiles
        .where((file) => file.language == effectiveLanguage)
        .toList();
    
    // Sort by creation date (newest first)
    currentLanguageFiles.sort((a, b) => b.created.compareTo(a.created));
    
    return currentLanguageFiles;
  }
}