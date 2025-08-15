import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tripthread/providers/auth_provider.dart';
import 'package:tripthread/widgets/custom_text_field.dart';
import 'package:tripthread/widgets/loading_button.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    print(
        'LoginScreen: login success = $success, isAuthenticated = ${authProvider.isAuthenticated}');
    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      // Persist inline error; do not auto-dismiss via SnackBar
      authProvider.markErrorAsShown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo and Title
                Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.travel_explore,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue your travel journey',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Email is required'),
                    EmailValidator(errorText: 'Please enter a valid email'),
                  ]),
                  onChanged: (_) {
                    // Clear error when user starts typing after an error
                    final authProvider = context.read<AuthProvider>();
                    if (authProvider.error != null) {
                      authProvider.clearError();
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator:
                      RequiredValidator(errorText: 'Password is required'),
                  onChanged: (_) {
                    // Clear error when user starts typing after an error
                    final authProvider = context.read<AuthProvider>();
                    if (authProvider.error != null) {
                      authProvider.clearError();
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Persistent Error Message
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return AnimatedBuilder(
                      animation: authProvider.uiNotifier,
                      builder: (context, _) {
                        if (authProvider.error == null) {
                          return const SizedBox.shrink();
                        }
                        return Container(
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
                                  authProvider.error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 18,
                                ),
                                onPressed: () {
                                  authProvider.clearError();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return LoadingButton(
                      onPressed: _handleLogin,
                      isLoading: authProvider.isLoading,
                      child: const Text('Sign In'),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.error != null) {
                          authProvider.clearError();
                        }
                        context.go('/signup');
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
    // );
  }
}
