import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:tripthread/providers/auth_provider.dart';
import 'package:tripthread/providers/user_provider.dart';
import 'package:tripthread/providers/trip_provider.dart';
import 'package:tripthread/services/api_service.dart';
import 'package:tripthread/services/storage_service.dart';
import 'package:tripthread/services/trip_service.dart';
import 'package:tripthread/services/connectivity_service.dart';
import 'package:tripthread/screens/splash_screen.dart';
import 'package:tripthread/screens/auth/login_screen.dart';
import 'package:tripthread/screens/auth/signup_screen.dart';
import 'package:tripthread/screens/home/home_screen.dart';
import 'package:tripthread/screens/profile/profile_screen.dart';
import 'package:tripthread/screens/profile/edit_profile_screen.dart';
import 'package:tripthread/screens/trip/create_trip_screen.dart';
import 'package:tripthread/screens/trip/trip_detail_screen.dart';
import 'package:tripthread/screens/trip/trip_thread_screen.dart';
import 'package:tripthread/utils/app_theme.dart';
import 'package:tripthread/utils/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize services
    final storageService = StorageService();
    await storageService.init();

    final connectivityService = ConnectivityService();
    await connectivityService.initialize();

    final apiService = ApiService();
    final tripService = TripService();

    runApp(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storageService),
          Provider<ApiService>.value(value: apiService),
          Provider<TripService>.value(value: tripService),
          ChangeNotifierProvider<ConnectivityService>.value(
              value: connectivityService),
          ChangeNotifierProvider<AuthProvider>(
            create: (context) => AuthProvider(
              apiService: apiService,
              storageService: storageService,
            ),
          ),
          ChangeNotifierProvider<UserProvider>(
            create: (context) => UserProvider(apiService: apiService),
          ),
          ChangeNotifierProvider<TripProvider>(
            create: (context) {
              final provider = TripProvider(tripService: tripService);
              tripService.setStorageService(storageService);
              return provider;
            },
          ),
        ],
        child: TripThreadAppRouter(),
      ),
    );
  } catch (error) {
    ErrorHandler.logError(error, context: 'App initialization');

    // Show error screen or fallback
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to initialize app'),
              const SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    ));
  }
}

class TripThreadAppRouter extends StatelessWidget {
  TripThreadAppRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp.router(
          title: 'TripThread',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _createRouter(authProvider),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final authProvider = context.watch<AuthProvider>();
            final connectivity = context.watch<ConnectivityService>();
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                // 👇 Only show splash while loading, with debug print
                if (authProvider.isLoading) ...[
                  (() {
                    debugPrint('Rendering SplashScreen');
                    return IgnorePointer(
                      ignoring: false,
                      child: const SplashScreen(),
                    );
                  })(),
                ],
                // 👇 Offline banner
                if (!connectivity.isConnected)
                  Positioned(
                    top: MediaQuery.of(context).padding.top,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.red,
                      child: const Text(
                        'No internet connection',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String?
      _lastLocation; // place this outside the function (as static or top-level)

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Page not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
      refreshListenable: authProvider,
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isLoading = authProvider.isLoading;
        final isLoggedIn = authProvider.isAuthenticated;
        final location = state.uri.toString();

        // ✅ Log only when location actually changes
        if (location != _lastLocation) {
          print('[GoRouter] location changed to: $location');
          _lastLocation = location;
        }

        if (isLoading) return null;

        if (!isLoggedIn && location != '/login' && location != '/signup') {
          return '/login';
        }

        if (isLoggedIn && (location == '/login' || location == '/signup')) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/profile/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return ProfileScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/create-trip',
          builder: (context, state) => const CreateTripScreen(),
        ),
        GoRoute(
          path: '/trip/:tripId',
          builder: (context, state) {
            final tripId = state.pathParameters['tripId']!;
            return TripDetailScreen(tripId: tripId);
          },
        ),
        GoRoute(
          path: '/trip/:tripId/thread',
          builder: (context, state) {
            final tripId = state.pathParameters['tripId']!;
            return TripThreadScreen(tripId: tripId);
          },
        ),
      ],
    );
  }
}
