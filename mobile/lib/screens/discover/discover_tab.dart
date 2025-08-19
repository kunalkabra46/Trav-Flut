import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripthread/providers/user_provider.dart';
import 'package:tripthread/providers/feed_provider.dart';
import 'package:tripthread/providers/auth_provider.dart';
import 'package:tripthread/models/trip.dart';
import 'package:go_router/go_router.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _tripsScrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _showUserSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _tripsScrollController.addListener(_onTripsScroll);
    _loadInitialTrips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tripsScrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadInitialTrips() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FeedProvider>().loadDiscoverTrips(refresh: true);
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSearching = true;
          _showUserSearch = query.isNotEmpty;
        });

        if (query.isNotEmpty) {
          // Search for users
          context.read<UserProvider>().searchUsers(
                search: query,
                refresh: true,
              );
        }

        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.hasMoreUsers && !userProvider.isDiscoverLoading) {
        userProvider.searchUsers(
          search:
              _searchController.text.isEmpty ? null : _searchController.text,
        );
      }
    }
  }

  void _onTripsScroll() {
    if (_tripsScrollController.position.pixels >=
        _tripsScrollController.position.maxScrollExtent - 200) {
      final feedProvider = context.read<FeedProvider>();
      if (feedProvider.hasMoreDiscoverTrips &&
          !feedProvider.isDiscoverTripsLoading) {
        feedProvider.loadDiscoverTrips();
      }
    }
  }

  Future<void> _toggleFollow(String userId, bool isCurrentlyFollowing) async {
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;

    try {
      if (isCurrentlyFollowing) {
        await userProvider.unfollowUser(userId, currentUserId: currentUserId);
      } else {
        await userProvider.followUser(userId, currentUserId: currentUserId);
      }

      // Update local state optimistically
      userProvider.updateFollowStatus(userId, !isCurrentlyFollowing);

      // Refresh the discover list to get updated follow statuses
      userProvider.searchUsers(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        refresh: true,
      );
    } catch (e) {
      // Revert optimistic update on error
      userProvider.updateFollowStatus(userId, isCurrentlyFollowing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to ${isCurrentlyFollowing ? 'unfollow' : 'follow'} user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search users or trips...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _showUserSearch = false;
                              });
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Content based on search state
          Expanded(
            child: _showUserSearch
                ? _buildUserSearchResults()
                : _buildDiscoverTrips(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSearchResults() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.discoverUsers.isEmpty &&
            userProvider.isDiscoverLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userProvider.discoverUsers.isEmpty &&
            userProvider.discoverError == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your search or check back later',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (userProvider.discoverError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading users',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userProvider.discoverError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    userProvider.clearDiscoverError();
                    userProvider.searchUsers(refresh: true);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            userProvider.searchUsers(refresh: true);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: userProvider.discoverUsers.length + 1,
            itemBuilder: (context, index) {
              if (index == userProvider.discoverUsers.length) {
                // Loading indicator at the bottom
                if (userProvider.isDiscoverLoading &&
                    userProvider.hasMoreUsers) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox.shrink();
              }

              final user = userProvider.discoverUsers[index];
              final isFollowing = user['isFollowing'] ?? false;
              final isFollowedBy = user['isFollowedBy'] ?? false;

              return _buildUserCard(context, user, isFollowing, isFollowedBy);
            },
          ),
        );
      },
    );
  }

  Widget _buildDiscoverTrips() {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        if (feedProvider.discoverTrips.isEmpty &&
            feedProvider.isDiscoverTripsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (feedProvider.discoverTrips.isEmpty &&
            feedProvider.discoverTripsError == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.explore_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No trips to discover',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Follow some travelers to see their amazing journeys',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (feedProvider.discoverTripsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading trips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feedProvider.discoverTripsError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    feedProvider.clearDiscoverTripsError();
                    feedProvider.loadDiscoverTrips(refresh: true);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            feedProvider.loadDiscoverTrips(refresh: true);
          },
          child: GridView.builder(
            controller: _tripsScrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: feedProvider.discoverTrips.length +
                (feedProvider.isDiscoverTripsLoading &&
                        feedProvider.hasMoreDiscoverTrips
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              if (index == feedProvider.discoverTrips.length) {
                // Loading indicator at the bottom
                return const Center(child: CircularProgressIndicator());
              }

              final trip = feedProvider.discoverTrips[index];
              return _buildDiscoverTripCard(context, trip);
            },
          ),
        );
      },
    );
  }

  Widget _buildDiscoverTripCard(BuildContext context, Trip trip) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () =>
            context.go('/trip/${trip.id}', extra: {'from': '/discover'}),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: trip.coverMediaUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.network(
                          trip.coverMediaUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildTripPlaceholder(context, trip);
                          },
                        ),
                      )
                    : _buildTripPlaceholder(context, trip),
              ),
            ),

            // Trip info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Row(
                      children: [
                        _buildCompactStatusBadge(context, trip.status),
                        const Spacer(),
                        if (trip.mood != null)
                          Text(
                            _getTripMoodEmoji(trip.mood!),
                            style: const TextStyle(fontSize: 16),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      trip.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Destination
                    Text(
                      trip.destinations.first,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Author info
                    if (trip.user != null)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            backgroundImage: trip.user!.avatarUrl != null
                                ? NetworkImage(trip.user!.avatarUrl!)
                                : null,
                            child: trip.user!.avatarUrl == null
                                ? Text(
                                    trip.user!.name
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        'U',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              trip.user!.name ?? 'Unknown',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripPlaceholder(BuildContext context, Trip trip) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.travel_explore,
            size: 32,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            trip.destinations.first,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusBadge(BuildContext context, TripStatus status) {
    Color color;
    String label;

    switch (status) {
      case TripStatus.upcoming:
        color = Colors.orange;
        label = 'Soon';
        break;
      case TripStatus.ongoing:
        color = Colors.green;
        label = 'Live';
        break;
      case TripStatus.ended:
        color = Colors.blue;
        label = 'Done';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  String _getTripMoodEmoji(TripMood mood) {
    switch (mood) {
      case TripMood.relaxed:
        return '😌';
      case TripMood.adventure:
        return '🏔️';
      case TripMood.spiritual:
        return '🧘';
      case TripMood.cultural:
        return '🏛️';
      case TripMood.party:
        return '🎉';
      case TripMood.mixed:
        return '🌈';
    }
  }

  Widget _buildUserCard(
    BuildContext context,
    Map<String, dynamic> user,
    bool isFollowing,
    bool isFollowedBy,
  ) {
    final username = user['username'] ?? 'No username';
    final name = user['name'] ?? 'No name';
    final bio = user['bio'];
    final avatarUrl = user['avatarUrl'];
    final isPrivate = user['isPrivate'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey[600],
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey[600],
                    ),
            ),

            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPrivate)
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@$username',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isFollowedBy) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        'Follows you',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Follow Button
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () => _toggleFollow(user['id'], isFollowing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? Colors.grey[200]
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor:
                      isFollowing ? Colors.grey[700] : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
