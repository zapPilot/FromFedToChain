import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/audio_content.dart';
import '../models/audio_file.dart';

class ContentService extends ChangeNotifier {
  static const String contentDir = 'content';
  static const String audioDir = 'audio';
  
  List<AudioContent> _contents = [];
  List<AudioFile> _audioFiles = [];
  bool _isLoading = false;
  String? _error;
  
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
      await Future.wait([
        _loadContentFiles(),
        _loadAudioFiles(),
      ]);
    } catch (e) {
      _error = 'Failed to load content: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load content files from the content directory
  Future<void> _loadContentFiles() async {
    final contentDirectory = Directory(contentDir);
    if (!contentDirectory.existsSync()) {
      throw Exception('Content directory not found: $contentDir');
    }

    final contents = <AudioContent>[];

    // Iterate through language directories
    await for (final languageDir in contentDirectory.list()) {
      if (languageDir is Directory) {
        final language = path.basename(languageDir.path);
        
        // Iterate through category directories
        await for (final categoryDir in languageDir.list()) {
          if (categoryDir is Directory) {
            final category = path.basename(categoryDir.path);
            
            // Iterate through JSON files
            await for (final file in categoryDir.list()) {
              if (file is File && file.path.endsWith('.json')) {
                try {
                  final jsonString = await file.readAsString();
                  final jsonData = json.decode(jsonString);
                  final content = AudioContent.fromJson(jsonData);
                  contents.add(content);
                } catch (e) {
                  if (kDebugMode) {
                    print('Error loading content file ${file.path}: $e');
                  }
                }
              }
            }
          }
        }
      }
    }

    _contents = contents;
  }

  // Load audio files from the audio directory
  Future<void> _loadAudioFiles() async {
    final audioDirectory = Directory(audioDir);
    if (!audioDirectory.existsSync()) {
      throw Exception('Audio directory not found: $audioDir');
    }

    final audioFiles = <AudioFile>[];

    // Iterate through language directories
    await for (final languageDir in audioDirectory.list()) {
      if (languageDir is Directory) {
        final language = path.basename(languageDir.path);
        
        // Iterate through category directories
        await for (final categoryDir in languageDir.list()) {
          if (categoryDir is Directory) {
            final category = path.basename(categoryDir.path);
            
            // Iterate through audio files
            await for (final file in categoryDir.list()) {
              if (file is File && file.path.endsWith('.wav')) {
                try {
                  final stat = await file.stat();
                  final fileName = path.basename(file.path);
                  final id = path.basenameWithoutExtension(fileName);
                  
                  final audioFile = AudioFile.fromFileInfo(
                    id: id,
                    language: language,
                    category: category,
                    filePath: file.path,
                    fileName: fileName,
                    sizeInBytes: stat.size,
                    created: stat.changed,
                  );
                  
                  audioFiles.add(audioFile);
                } catch (e) {
                  if (kDebugMode) {
                    print('Error loading audio file ${file.path}: $e');
                  }
                }
              }
            }
          }
        }
      }
    }

    _audioFiles = audioFiles;
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
}