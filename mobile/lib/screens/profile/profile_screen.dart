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
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    final isOwnProfile = authProvider.currentUser?.id == widget.userId;
    
    debugPrint('[ProfileScreen] Loading profile data for userId: ${widget.userId}');
    debugPrint('[ProfileScreen] Current user: ${authProvider.currentUser?.id}');
    debugPrint('[ProfileScreen] isOwnProfile: $isOwnProfile');
    
    try {
      // Load profile data in parallel
      await Future.wait([
        userProvider.fetchUser(widget.userId),
        userProvider.fetchUserStats(widget.userId),
        userProvider.fetchDetailedFollowStatus(widget.userId),
      ]);

      // Always load pending follow requests for current user's profile
      if (authProvider.currentUser?.id == widget.userId) {
        debugPrint('[ProfileScreen] Loading pending follow requests for current user');
        await userProvider.loadPendingFollowRequests();
        debugPrint('[ProfileScreen] Loaded ${userProvider.pendingFollowRequests.length} pending requests');
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
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

    debugPrint('Follow toggle - Current state: following=$isCurrentlyFollowing, pending=$isRequestPending, private=$isPrivate');

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
      debugPrint('Attempting to unfollow user');
      success = await userProvider.unfollowUser(widget.userId, currentUserId: currentUser.id);
    } else if (isRequestPending) {
      // Cancel follow request
      debugPrint('Attempting to cancel follow request');
      success = await userProvider.cancelFollowRequest(widget.userId);
    } else {
      // Send follow request or follow directly
      if (isPrivate) {
        debugPrint('Attempting to send follow request to private user');
        success = await userProvider.sendFollowRequest(widget.userId);
      } else {
        debugPrint('Attempting to follow public user');
        success = await userProvider.followUser(widget.userId, currentUserId: currentUser.id);
      }
    }

    if (!mounted) return;

    if (success) {
      debugPrint('Action successful, refreshing profile data');
      
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
      
      // Force a rebuild to update the UI
      setState(() {});
    } else {
      debugPrint('Action failed: ${userProvider.error}');
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
        // Always fetch detailed follow status to show correct button states
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
    debugPrint('[ProfileScreen] Building profile screen for userId: ${widget.userId}');
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final currentUser = authProvider.currentUser;
        final user = userProvider.getUser(widget.userId);
        final stats = userProvider.getUserStats(widget.userId);
        final isOwnProfile = currentUser?.id == widget.userId;
        
        // Ensure follow requests are loaded for own profile
        if (isOwnProfile && !userProvider.isFollowRequestsLoading) {
          debugPrint('[ProfileScreen] Loading follow requests for own profile');
          userProvider.loadPendingFollowRequests();
        }
        
        final pendingRequests = isOwnProfile ? userProvider.pendingFollowRequests : [];
        
        debugPrint('[ProfileScreen] isOwnProfile: $isOwnProfile (currentUserId: ${currentUser?.id})');
        debugPrint('[ProfileScreen] pendingRequests: ${pendingRequests.length}');

        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: Text('User not found'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(user.username ?? 'Profile'),
            actions: [
              // Follow requests button for own profile
              if (isOwnProfile) 
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      tooltip: 'Follow Requests',
                      onPressed: () {
                        debugPrint('[ProfileScreen] Opening follow requests');
                        context.push('/follow-requests');
                      },
                    ),
                    if (pendingRequests.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            pendingRequests.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              // Settings button
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                ),
              // Debug button with better visibility
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.bug_report),
                  tooltip: 'Debug Info',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                  ),
                  color: Colors.orange,
                  onPressed: () {
                    debugPrint('[ProfileScreen] Debug button pressed');
                    debugPrint('[ProfileScreen] Current user: ${currentUser?.username}');
                    debugPrint('[ProfileScreen] Profile user: ${user.username}');
                    debugPrint('[ProfileScreen] Pending requests: ${pendingRequests.length}');
                    debugPrint('[ProfileScreen] isOwnProfile: $isOwnProfile');
                  },
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshProfile,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            strokeWidth: 3,
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
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
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
                  _buildProfileHeader(
                    context,
                    user,
                    stats,
                    isOwnProfile,
                    userProvider.getDetailedFollowStatus(widget.userId)?.isFollowing ?? false,
                    userProvider.getDetailedFollowStatus(widget.userId)?.isRequestPending ?? false,
                    userProvider.isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Trips Section
                  _buildTripsSection(context, user, isOwnProfile),
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
                            ? 'Cancel Request' 
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
