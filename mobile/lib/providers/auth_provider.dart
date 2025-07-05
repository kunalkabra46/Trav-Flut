import 'package:flutter/foundation.dart';
import 'package:tripthread/models/user.dart';
import 'package:tripthread/services/api_service.dart';
import 'package:tripthread/services/storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.signup(
        email: email,
        password: password,
        name: name,
        username: username,
      );

      print(
          '[AuthProvider] signup response: success=${response.success}, error=${response.error}, data=${response.data}');
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
        print('[AuthProvider] signup error set: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      print('[AuthProvider] signup catch error: $e');
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

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Login failed';
        print('[AuthProvider] login error set: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      print('[AuthProvider] login catch error: $e');
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
    // if (_error != null) {
      print('[AuthProvider] clearError called, clearing error');
      _error = null;
      notifyListeners();
    // }
  }

  // Called by ApiService when refresh fails or user is unauthorized
  Future<void> forceLogout({String? message}) async {
    _currentUser = null;
    await _storageService.clearTokens();
    _error = message;
    notifyListeners();
  }
}
