import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/color_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../providers/ai_ide_provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/ai_ide_sync_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/update_dialog.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  String _statusText = 'Starting up...';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _initialize();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 600));

    // 1. Request permissions
    _setStatus('Requesting permissions...');
    await _requestPermissions();

    if (!mounted) return;

    // 2. Sync AI IDEs
    _setStatus('Loading AI tools...');
    final settings = ref.read(settingsProvider);
    final syncService = ref.read(aiIdeSyncServiceProvider);
    await syncService.sync(settings.aiIdeListUrl);

    if (!mounted) return;

    ref.read(aiIdeProvider.notifier).reload();
    await ref.read(settingsProvider.notifier).updateLastAiIdeSync();

    if (!mounted) return;

    // 3. Check for app updates
    _setStatus('Checking for updates...');
    try {
      final info = await PackageInfo.fromPlatform();
      await ref.read(updateProvider.notifier).check(info.version);
    } catch (_) {}

    if (!mounted) return;

    // 4. Mark onboarding complete on first run
    if (!settings.hasCompletedOnboarding) {
      await ref.read(settingsProvider.notifier).setOnboardingComplete();
    }

    if (!mounted) return;

    _setStatus('Ready!');
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    // Show update dialog if available (non-blocking)
    final updateState = ref.read(updateProvider);
    if (updateState.availableUpdate != null && mounted) {
      await UpdateDialog.show(context, updateState.availableUpdate!);
    }

    if (!mounted) return;

    // Navigate based on biometric setting
    final updatedSettings = ref.read(settingsProvider);
    if (updatedSettings.biometricEnabled) {
      context.go('/lock');
    } else {
      ref.read(authProvider.notifier).markAuthenticated();
      context.go('/dashboard');
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  void _setStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 100, color: AppColors.accentLight),
              const SizedBox(height: 24),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppConstants.appTagline,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.accentLight,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
