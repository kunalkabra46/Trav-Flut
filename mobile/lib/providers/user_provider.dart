import 'package:flutter/foundation.dart';
import 'package:tripthread/models/user.dart';
import 'package:tripthread/services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService;

  UserProvider({required ApiService apiService}) : _apiService = apiService;

  final Map<String, User> _userCache = {};
  final Map<String, UserStats> _statsCache = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  User? getUser(String userId) => _userCache[userId];
  UserStats? getUserStats(String userId) => _statsCache[userId];

  Future<User?> fetchUser(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getUser(userId);

      if (response.success && response.data != null) {
        _userCache[userId] = response.data!;
        _isLoading = false;
        notifyListeners();
        return response.data;
      } else {
        _error = response.error ?? 'Failed to fetch user';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Fetch user error: $e');
      return null;
    }
  }

  Future<UserStats?> fetchUserStats(String userId) async {
    try {
      final response = await _apiService.getUserStats(userId);

      if (response.success && response.data != null) {
        _statsCache[userId] = response.data!;
        notifyListeners();
        return response.data;
      } else {
        _error = response.error ?? 'Failed to fetch user stats';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      notifyListeners();
      debugPrint('Fetch user stats error: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
    bool? isPrivate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.updateProfile(
        userId: userId,
        name: name,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
        isPrivate: isPrivate,
      );

      if (response.success && response.data != null) {
        _userCache[userId] = response.data!;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  Future<bool> togglePrivacy(String userId) async {
    try {
      final response = await _apiService.togglePrivacy(userId);

      if (response.success && response.data != null) {
        _userCache[userId] = response.data!;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to toggle privacy';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      notifyListeners();
      debugPrint('Toggle privacy error: $e');
      return false;
    }
  }

  Future<bool> followUser(String userId) async {
    try {
      final response = await _apiService.followUser(userId);

      if (response.success) {
        // Refresh user stats
        await fetchUserStats(userId);
        return true;
      } else {
        _error = response.error ?? 'Failed to follow user';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      notifyListeners();
      debugPrint('Follow user error: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(String userId) async {
    try {
      final response = await _apiService.unfollowUser(userId);

      if (response.success) {
        // Refresh user stats
        await fetchUserStats(userId);
        return true;
      } else {
        _error = response.error ?? 'Failed to unfollow user';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      notifyListeners();
      debugPrint('Unfollow user error: $e');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCache() {
    _userCache.clear();
    _statsCache.clear();
    notifyListeners();
  }
}
