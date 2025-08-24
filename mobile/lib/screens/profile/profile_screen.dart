import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripthread/providers/auth_provider.dart';
import 'package:tripthread/providers/user_provider.dart';
import 'package:tripthread/models/user.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    // Clear any previous errors
    userProvider.clearError();

    try {
      // Fetch user profile
      await userProvider.fetchUser(widget.userId);

      // Fetch user stats
      await userProvider.fetchUserStats(widget.userId);

      // Fetch follow status (only if not own profile)
      final currentUser = authProvider.currentUser;
      if (currentUser != null && currentUser.id != widget.userId) {
        await userProvider.fetchFollowStatus(widget.userId);
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    }
  }

  Future<void> _handleFollowToggle() async {
    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    // Fetch latest follow status first
    final detailedStatus = await userProvider.fetchDetailedFollowStatus(widget.userId);
    final isCurrentlyFollowing = detailedStatus?.isFollowing ?? false;
    final isRequestPending = detailedStatus?.isRequestPending ?? false;
    final isPrivate = detailedStatus?.isPrivate ?? false;

    if (!mounted) return;

    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to follow users'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool success = false;
    
    if (isCurrentlyFollowing) {
      // Unfollow user
      success = await userProvider.unfollowUser(widget.userId, currentUserId: currentUser.id);
    } else if (isRequestPending) {
      // Cancel follow request
      success = await userProvider.cancelFollowRequest(widget.userId);
    } else {
      // Send follow request or follow directly
      if (isPrivate) {
        success = await userProvider.sendFollowRequest(widget.userId);
      } else {
        success = await userProvider.followUser(widget.userId, currentUserId: currentUser.id);
      }
    }

    if (!mounted) return;

    if (success) {
      // Refresh both follow status and stats
      await Future.wait([
        userProvider.fetchDetailedFollowStatus(widget.userId),
        userProvider.fetchUserStats(widget.userId),
        userProvider.fetchUserStats(currentUser.id),
      ]);
      
      if (!mounted) return;

      String message;
      if (isCurrentlyFollowing) {
        message = 'Unfollowed successfully';
      } else if (isRequestPending) {
        message = 'Follow request cancelled';
      } else if (isPrivate) {
        message = 'Follow request sent';
      } else {
        message = 'Following successfully';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? 'Failed to update follow status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshProfile() async {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    
    // Clear any previous errors
    userProvider.clearError();

    try {
      // Load profile data in parallel
      await Future.wait([
        userProvider.fetchUser(widget.userId),
        userProvider.fetchUserStats(widget.userId),
        if (authProvider.currentUser?.id != widget.userId)
          userProvider.fetchDetailedFollowStatus(widget.userId),
      ]);

      if (!mounted) return;

      // Load follow requests if it's the current user's profile
      if (authProvider.currentUser?.id == widget.userId) {
        await userProvider.loadPendingFollowRequests();
      }
    } catch (e) {
      debugPrint('Error refreshing profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final currentUser = authProvider.currentUser;
        final profileUser = userProvider.getUser(widget.userId);
        final userStats = userProvider.getUserStats(widget.userId);
        final isOwnProfile = currentUser?.id == widget.userId;
        final detailedFollowStatus = userProvider.getDetailedFollowStatus(widget.userId);
        final isFollowing = detailedFollowStatus?.isFollowing ?? false;
        final isRequestPending = detailedFollowStatus?.isRequestPending ?? false;

        if (_isInitialLoad && profileUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (userProvider.isLoading && profileUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profileUser == null && !userProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Get the 'from' parameter or default to home
                  final extra = GoRouterState.of(context).extra;
                  final from = (extra is Map && extra['from'] != null)
                      ? extra['from'] as String
                      : '/home';
                  context.go(from);
                },
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'User not found',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This profile may have been deleted or doesn\'t exist.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(profileUser?.name ?? 'Profile'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Get the 'from' parameter or default to home
                final extra = GoRouterState.of(context).extra;
                final from = (extra is Map && extra['from'] != null)
                    ? extra['from'] as String
                    : '/home';
                context.go(from);
              },
            ),
            actions: [
              if (isOwnProfile)
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.person_add_outlined),
                      if (userProvider.pendingFollowRequests.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '${userProvider.pendingFollowRequests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    context.push('/follow-requests');
                  },
                ),
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    // Pass current route as 'from' parameter
                    context.push('/edit-profile',
                        extra: {'from': '/profile/${widget.userId}'});
                  },
                ),
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    // TODO: Navigate to settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon')),
                    );
                  },
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Show error banner if there's an error
                  if (userProvider.error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userProvider.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              userProvider.clearError();
                              _refreshProfile();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),

                  // Profile Header
                  if (profileUser != null)
                    _buildProfileHeader(
                      context,
                      profileUser,
                      userStats,
                      isOwnProfile,
                      isFollowing,
                      isRequestPending,
                      userProvider.isLoading,
                    ),

                  const SizedBox(height: 24),

                  // Trips Section
                  if (profileUser != null)
                    _buildTripsSection(context, profileUser, isOwnProfile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    User user,
    UserStats? stats,
    bool isOwnProfile,
    bool isFollowing,
    bool isRequestPending,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 16),

          // Name and Privacy Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name ?? 'User',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (user.isPrivate) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.lock_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),

          // Username
          if (user.username != null) ...[
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],

          // Bio
          if (user.bio != null) ...[
            const SizedBox(height: 12),
            Text(
              user.bio!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),

          // Stats Row
          if (stats != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(context, stats.tripCount.toString(), 'Trips'),
                _buildStatColumn(
                    context, stats.followerCount.toString(), 'Followers'),
                _buildStatColumn(
                    context, stats.followingCount.toString(), 'Following'),
              ],
            ),

          const SizedBox(height: 20),

          // Action Buttons
          if (isOwnProfile)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context.push('/edit-profile',
                      extra: {'from': '/profile/${widget.userId}'});
                },
                child: const Text('Edit Profile'),
              ),
            )
          else if (user.isPrivate && !isFollowing && !isRequestPending)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_outlined,
                        size: 32,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This account is private',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Follow to see their trips and posts',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleFollowToggle,
                    child: const Text('Send Follow Request'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleFollowToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing || isRequestPending
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.primary,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isFollowing 
                          ? 'Unfollow' 
                          : isRequestPending 
                            ? 'Request Sent' 
                            : 'Follow'
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripsSection(
      BuildContext context, User user, bool isOwnProfile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOwnProfile ? 'Your Trips' : '${user.name}\'s Trips',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Column(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Text(
                  'No trips yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
