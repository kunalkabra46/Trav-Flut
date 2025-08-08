import 'package:flutter/foundation.dart';
import 'package:tripthread/models/user.dart';
import 'package:tripthread/services/api_service.dart';
import 'package:tripthread/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  User? _currentUser;
  bool _isLoading = true;
  String? _error;
  bool _hasShownError = false;

  // Notifier dedicated for UI-only updates (e.g., error banner),
  // so we don't trigger global rebuilds/route refreshes.
  final ChangeNotifier uiNotifier = ChangeNotifier();

  AuthProvider({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService {
    _apiService.setStorageService(_storageService);
    _initializeAuth();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  Future<void> _initializeAuth() async {
    print('AuthProvider: Starting initialization');
    _isLoading = true;
    notifyListeners();
    try {
      print('AuthProvider: Checking tokens...');
      final hasTokens = await _storageService
          .hasValidTokens()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        print('AuthProvider: hasValidTokens() timed out!');
        throw Exception('hasValidTokens() timed out');
      });
      print('AuthProvider: hasTokens = $hasTokens');
      if (hasTokens) {
        print('AuthProvider: Getting userId...');
        final userId = await _storageService
            .getUserId()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          print('AuthProvider: getUserId() timed out!');
          throw Exception('getUserId() timed out');
        });
        print('AuthProvider: userId = $userId');
        if (userId != null) {
          print('AuthProvider: Calling getUser...');
          final response = await _apiService
              .getUser(userId)
              .timeout(const Duration(seconds: 5), onTimeout: () {
            print('AuthProvider: getUser() timed out!');
            throw Exception('getUser() timed out');
          });
          print(
              'AuthProvider: getUser response = ${response.success} | ${response.data} | ${response.error}');
          if (response.success && response.data != null) {
            _currentUser = response.data;
          } else {
            print('AuthProvider: Invalid tokens, clearing');
            await _storageService.clearTokens();
          }
        }
      }
    } catch (e, stack) {
      _error = 'Failed to initialize authentication';
      print('AuthProvider: Exception in _initializeAuth: $e\n$stack');
      await _storageService.clearTokens();
    } finally {
      print('AuthProvider: Initialization complete, isLoading = false');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String name,
    String? username,
  }) async {
    try {
      _setLoadingState(true);
      _clearError();

      final response = await _apiService.signup(
        email: email,
        password: password,
        name: name,
        username: username,
      );

      print(
          '[AuthProvider] signup response: success=${response.success}, error=${response.error}');

      if (response.success && response.data != null) {
        final authData = response.data!;
        _currentUser = authData.user;

        await _storageService.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
          userId: authData.user.id,
        );

        _setLoadingState(false);
        return true;
      } else {
        _setError(response.error ?? 'Signup failed. Please try again.');
        print('[AuthProvider] signup error set: $_error');
        _setLoadingState(false);
        return false;
      }
    } catch (e) {
      print('[AuthProvider] signup catch error: $e');
      _setError('Network error. Please check your connection and try again.');
      _setLoadingState(false);
      debugPrint('Signup error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoadingState(true);
      _clearError(); // Clear any previous error

      final response = await _apiService.login(
        email: email,
        password: password,
      );

      print(
          '[AuthProvider] login response: success=${response.success}, error=${response.error}, data=${response.data}');

      if (response.success && response.data != null) {
        final authData = response.data!;
        _currentUser = authData.user;

        await _storageService.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
          userId: authData.user.id,
        );

        _setLoadingState(false);
        return true;
      } else {
        _setError(
            response.error ?? 'Login failed. Please check your credentials.');
        print('[AuthProvider] login error set: $_error');
        _setLoadingState(false);
        return false;
      }
    } catch (e) {
      print('[AuthProvider] login catch error: $e');
      _setError('Network error. Please check your connection and try again.');
      _setLoadingState(false);
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null) {
        await _apiService.logout(refreshToken);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _currentUser = null;
      await _storageService.clearTokens();
      notifyListeners();
    }
  }

  // Helper methods for cleaner state management
  void _setLoadingState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _hasShownError = false;
    uiNotifier.notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      _hasShownError = false;
      uiNotifier.notifyListeners();
    }
  }

  bool get shouldShowError => _error != null && !_hasShownError;

  void clearError() {
    print('[AuthProvider] clearError called by user');
    _clearError();
  }

  // Method to mark error as shown (for toast notifications)
  void markErrorAsShown() {
    _hasShownError = true;
    uiNotifier.notifyListeners();
  }

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // Called by ApiService when refresh fails or user is unauthorized
  Future<void> forceLogout({String? message}) async {
    _currentUser = null;
    await _storageService.clearTokens();
    _error = message;
    notifyListeners();
  }
}
