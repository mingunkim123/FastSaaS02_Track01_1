import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/theme/app_theme.dart';

/// Login page with OAuth sign-in options (Google and Kakao)
/// Displays centered layout with app title and OAuth buttons
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;
  String? _errorMessage;

  /// Handle Google OAuth sign-in
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement Google OAuth sign-in
      // Requires: Google OAuth configuration in Supabase console
      // Steps:
      // 1. Set up Google OAuth app in Google Cloud Console
      // 2. Add OAuth Credential (Web Client ID) to Supabase Auth providers
      // 3. Configure redirect URI: [APP_URL]/auth/v1/callback
      // 4. Use supabaseAuthProvider to call signInWithOAuth
      //
      // Example implementation:
      // final authService = ref.read(supabaseAuthProvider);
      // await authService.client.auth.signInWithOAuth(
      //   'google',
      //   redirectTo: 'com.fastsaas02.app://auth/callback',
      // );

      _showErrorSnackBar('Google OAuth is not yet configured');
    } catch (e) {
      _showErrorSnackBar('Google sign-in failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle Kakao OAuth sign-in
  Future<void> _handleKakaoSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement Kakao OAuth sign-in
      // Requires: Kakao app setup and custom OAuth flow
      // Steps:
      // 1. Register app in Kakao Developers console
      // 2. Set up Kakao OAuth configuration
      // 3. Implement Kakao auth flow:
      //    - Get Kakao auth code
      //    - Exchange code for access token
      //    - Call Supabase signInWithOAuth with custom provider or
      //    - Use Kakao access token to authenticate with Supabase
      // 4. Handle redirect URI: com.fastsaas02.app://auth/callback
      //
      // Current status: Awaiting Kakao app credentials and backend setup

      _showErrorSnackBar('Kakao OAuth is not yet configured');
    } catch (e) {
      _showErrorSnackBar('Kakao sign-in failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Display error message in snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 4),
      ),
    );
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final horizontalPadding = isMobile ? 24.0 : 48.0;
    final buttonWidth = isMobile ? double.infinity : 300.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Title
                Text(
                  '가계부',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Your Personal Finance Manager',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Google OAuth Button
                SizedBox(
                  width: buttonWidth,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Logo (using simple SVG-like representation)
                              Image.asset(
                                'assets/images/google_logo.png',
                                height: 24,
                                width: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback: show text-based icon
                                  return const Icon(
                                    Icons.account_circle,
                                    size: 24,
                                    color: Colors.black54,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sign in with Google',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kakao OAuth Button
                SizedBox(
                  width: buttonWidth,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleKakaoSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500), // Kakao yellow
                      foregroundColor: const Color(0xFF3C1E1E), // Kakao brown
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3C1E1E),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Kakao Logo (using simple SVG-like representation)
                              Image.asset(
                                'assets/images/kakao_logo.png',
                                height: 24,
                                width: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback: show text-based icon
                                  return const Icon(
                                    Icons.account_circle,
                                    size: 24,
                                    color: Color(0xFF3C1E1E),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sign in with Kakao',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: const Color(0xFF3C1E1E),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // Error message display
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                      border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.errorColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
