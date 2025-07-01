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
    try {
      print('AuthProvider: Starting initialization');
      _isLoading = true;
      notifyListeners();

      final hasTokens = await _storageService.hasValidTokens();
      print('AuthProvider: hasTokens = '
          '[32m$hasTokens[0m');
      if (hasTokens) {
        final userId = await _storageService.getUserId();
        print('AuthProvider: userId = '
            '[34m$userId[0m');
        if (userId != null) {
          final response = await _apiService.getUser(userId);
          print('AuthProvider: getUser response = '
              '\u001b[36m${response.success} | ${response.data} | ${response.error}\u001b[0m');
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
      debugPrint('Auth initialization error: $e');
      debugPrint('Stack: $stack');
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
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.signup(
        email: email,
        password: password,
        name: name,
        username: username,
      );

      if (response.success && response.data != null) {
        final authData = response.data!;
        _currentUser = authData.user;

        await _storageService.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
          userId: authData.user.id,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Signup failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Signup error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        final authData = response.data!;
        _currentUser = authData.user;

        await _storageService.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
          userId: authData.user.id,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
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

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
