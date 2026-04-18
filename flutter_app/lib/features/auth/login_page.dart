import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/providers/auth_provider.dart';
import 'package:flutter_app/shared/widgets/animated_fade_slide.dart';

// ============================================================
// [로그인 화면] login_page.dart
// OAuth 로그인 (Google via Supabase).
// 재설계: 브랜드 히어로 + 그라데이션 + 다크 모드 대응.
// ============================================================
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(supabaseAuthProvider);

      final redirectUrl = kIsWeb
          ? 'http://localhost:5173/auth/callback'
          : 'com.fastsaas02.app://auth/callback';

      await authService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
      // signInWithOAuth는 외부 브라우저를 띄우기만 함.
      // 세션은 딥링크 콜백 후 authStateProvider → GoRouter redirect가 처리.
    } catch (e) {
      _showError('Google 로그인 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleKakaoSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    // TODO: kakao_flutter_sdk 연동 예정
    _showError('카카오 로그인은 준비 중입니다.');
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.expense,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
    if (mounted) setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final horizontalPadding = isMobile ? 24.0 : 48.0;
    final contentWidth = isMobile ? double.infinity : 360.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    Color.alphaBlend(
                      theme.colorScheme.primary.withValues(alpha: 0.18),
                      AppColors.darkBackground,
                    ),
                  ]
                : [
                    const Color(0xFFF3F6FF),
                    Color.alphaBlend(
                      theme.colorScheme.primary.withValues(alpha: 0.10),
                      Colors.white,
                    ),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedFadeSlide(
                      child: _buildHero(theme),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    AnimatedFadeSlide(
                      delay: const Duration(milliseconds: 160),
                      child: _buildGoogleButton(theme),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AnimatedFadeSlide(
                      delay: const Duration(milliseconds: 240),
                      child: _buildKakaoButton(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (_errorMessage != null)
                      AnimatedFadeSlide(
                        child: _buildErrorBanner(theme),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.25),
                  theme.colorScheme.primary,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '민근 가계부',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'AI와 대화하며 관리하는 개인 가계부',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGoogleButton(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? theme.colorScheme.surface
              : Colors.white,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.google,
                    size: 20,
                    color: Color(0xFFEA4335),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Google로 계속하기',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildKakaoButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleKakaoSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: const Color(0xFF3C1E1E),
          elevation: 2,
          shadowColor: const Color(0xFFFEE500).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.comment,
              size: 20,
              color: Color(0xFF3C1E1E),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text(
              '카카오로 계속하기',
              style: TextStyle(
                color: Color(0xFF3C1E1E),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: AppColors.expense.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.expense,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
