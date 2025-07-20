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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      userProvider.fetchUser(widget.userId);
      userProvider.fetchUserStats(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final currentUser = authProvider.currentUser;
        final profileUser = userProvider.getUser(widget.userId);
        final userStats = userProvider.getUserStats(widget.userId);
        final isOwnProfile = currentUser?.id == widget.userId;

        if (userProvider.isLoading && profileUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profileUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(
              child: Text('User not found'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(profileUser.name ?? 'Profile'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Use explicit navigation instead of pop
                context.go('/home');
              },
            ),
            actions: [
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
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(
                    context, profileUser, userStats, isOwnProfile),

                const SizedBox(height: 24),

                // Trips Section
                _buildTripsSection(context, profileUser, isOwnProfile),
              ],
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
                  // TODO: Navigate to edit profile
                },
                child: const Text('Edit Profile'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement follow/unfollow
                },
                child: const Text('Follow'),
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
