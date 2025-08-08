import 'package:flutter/foundation.dart';
import '../models/audio_file.dart';

// A mock user model. In a real app, this would be more complex.
class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}

class AuthService with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  final List<AudioFile> _favorites = [];
  final List<AudioFile> _myPlaylist = [];

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  List<AudioFile> get favorites => _favorites;
  List<AudioFile> get myPlaylist => _myPlaylist;

  // Mock login
  Future<void> login(String email, String password) async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'test@test.com' && password == 'password') {
      _user = User(id: '1', name: 'Test User', email: email);
      _isAuthenticated = true;
      notifyListeners();
    } else {
      throw Exception('Invalid email or password');
    }
  }

  // Mock sign up
  Future<void> signUp(String name, String email, String password) async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 1));

    // In a real app, you would check if the email is already in use.
    _user = User(id: '2', name: name, email: email);
    _isAuthenticated = true;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    _user = null;
    _isAuthenticated = false;
    _favorites.clear();
    _myPlaylist.clear();
    notifyListeners();
  }

  // Favorites
  void addToFavorites(AudioFile audioFile) {
    if (!_favorites.contains(audioFile)) {
      _favorites.add(audioFile);
      notifyListeners();
    }
  }

  void removeFromFavorites(AudioFile audioFile) {
    _favorites.remove(audioFile);
    notifyListeners();
  }

  bool isFavorite(AudioFile audioFile) {
    return _favorites.contains(audioFile);
  }

  // Playlist
  void addToPlaylist(AudioFile audioFile) {
    if (!_myPlaylist.contains(audioFile)) {
      _myPlaylist.add(audioFile);
      notifyListeners();
    }
  }

  void removeFromPlaylist(AudioFile audioFile) {
    _myPlaylist.remove(audioFile);
    notifyListeners();
  }
}
