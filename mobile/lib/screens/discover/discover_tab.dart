import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripthread/providers/user_provider.dart';
import 'package:tripthread/services/api_service.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadInitialUsers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().searchUsers(refresh: true);
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSearching = true;
        });
        context.read<UserProvider>().searchUsers(
              search: query.isEmpty ? null : query,
              refresh: true,
            );
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

  Future<void> _toggleFollow(String userId, bool isCurrentlyFollowing) async {
    final userProvider = context.read<UserProvider>();
    final apiService = context.read<ApiService>();

    try {
      if (isCurrentlyFollowing) {
        await apiService.unfollowUser(userId);
      } else {
        await apiService.followUser(userId);
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
                hintText: 'Search users...',
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

          // User List
          Expanded(
            child: Consumer<UserProvider>(
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

                      return _buildUserCard(
                          context, user, isFollowing, isFollowedBy);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
