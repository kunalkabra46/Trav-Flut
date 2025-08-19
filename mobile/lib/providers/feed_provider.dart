import 'package:flutter/foundation.dart';
import 'package:tripthread/models/trip.dart';
import 'package:tripthread/services/api_service.dart';

class FeedProvider extends ChangeNotifier {
  final ApiService _apiService;

  FeedProvider({required ApiService apiService}) : _apiService = apiService;

  // Home Feed State
  final List<TripFinalPost> _homeFeedPosts = [];
  bool _isHomeFeedLoading = false;
  String? _homeFeedError;
  int _homeFeedPage = 1;
  bool _hasMoreHomeFeedPosts = true;

  // Discover Trips State
  final List<Trip> _discoverTrips = [];
  bool _isDiscoverTripsLoading = false;
  String? _discoverTripsError;
  int _discoverTripsPage = 1;
  bool _hasMoreDiscoverTrips = true;

  // Getters
  List<TripFinalPost> get homeFeedPosts => _homeFeedPosts;
  bool get isHomeFeedLoading => _isHomeFeedLoading;
  String? get homeFeedError => _homeFeedError;
  bool get hasMoreHomeFeedPosts => _hasMoreHomeFeedPosts;

  List<Trip> get discoverTrips => _discoverTrips;
  bool get isDiscoverTripsLoading => _isDiscoverTripsLoading;
  String? get discoverTripsError => _discoverTripsError;
  bool get hasMoreDiscoverTrips => _hasMoreDiscoverTrips;

  // Home Feed Methods
  Future<void> loadHomeFeed({bool refresh = false}) async {
    try {
      if (refresh) {
        _homeFeedPage = 1;
        _homeFeedPosts.clear();
        _hasMoreHomeFeedPosts = true;
        _homeFeedError = null;
      }

      if (!_hasMoreHomeFeedPosts) return;

      _isHomeFeedLoading = true;
      notifyListeners();

      final response = await _apiService.getHomeFeed(
        page: _homeFeedPage,
        limit: 20,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final posts = (data['items'] as List<dynamic>)
            .map((json) => TripFinalPost.fromJson(json as Map<String, dynamic>))
            .toList();
        final hasNext = data['hasNext'] as bool;

        if (refresh) {
          _homeFeedPosts.clear();
        }

        _homeFeedPosts.addAll(posts);
        _hasMoreHomeFeedPosts = hasNext;
        _homeFeedPage++;
        _homeFeedError = null;
      } else {
        _homeFeedError = response.error ?? 'Failed to load home feed';
      }
    } catch (e) {
      _homeFeedError = 'An unexpected error occurred';
      debugPrint('Load home feed error: $e');
    } finally {
      _isHomeFeedLoading = false;
      notifyListeners();
    }
  }

  // Discover Trips Methods
  Future<void> loadDiscoverTrips({
    bool refresh = false,
    String? status,
    String? mood,
  }) async {
    try {
      if (refresh) {
        _discoverTripsPage = 1;
        _discoverTrips.clear();
        _hasMoreDiscoverTrips = true;
        _discoverTripsError = null;
      }

      if (!_hasMoreDiscoverTrips) return;

      _isDiscoverTripsLoading = true;
      notifyListeners();

      final response = await _apiService.getDiscoverTrips(
        page: _discoverTripsPage,
        limit: 20,
        status: status,
        mood: mood,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final trips = (data['items'] as List<dynamic>)
            .map((json) => Trip.fromJson(json as Map<String, dynamic>))
            .toList();
        final hasNext = data['hasNext'] as bool;

        if (refresh) {
          _discoverTrips.clear();
        }

        _discoverTrips.addAll(trips);
        _hasMoreDiscoverTrips = hasNext;
        _discoverTripsPage++;
        _discoverTripsError = null;
      } else {
        _discoverTripsError = response.error ?? 'Failed to load discover trips';
      }
    } catch (e) {
      _discoverTripsError = 'An unexpected error occurred';
      debugPrint('Load discover trips error: $e');
    } finally {
      _isDiscoverTripsLoading = false;
      notifyListeners();
    }
  }

  // Clear methods
  void clearHomeFeedError() {
    _homeFeedError = null;
    notifyListeners();
  }

  void clearDiscoverTripsError() {
    _discoverTripsError = null;
    notifyListeners();
  }

  void resetHomeFeed() {
    _homeFeedPosts.clear();
    _homeFeedPage = 1;
    _hasMoreHomeFeedPosts = true;
    _homeFeedError = null;
    notifyListeners();
  }

  void resetDiscoverTrips() {
    _discoverTrips.clear();
    _discoverTripsPage = 1;
    _hasMoreDiscoverTrips = true;
    _discoverTripsError = null;
    notifyListeners();
  }

  void clearData() {
    _homeFeedPosts.clear();
    _discoverTrips.clear();
    _homeFeedError = null;
    _discoverTripsError = null;
    notifyListeners();
  }
}
