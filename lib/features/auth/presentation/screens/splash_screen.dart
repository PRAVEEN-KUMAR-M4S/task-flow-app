import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/services/biometric_service.dart';
import 'package:task_flow/core/storage/secure_storage_service.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _biometricPrompted = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await context.read<SessionCubit>().checkSession();
  }

  Future<void> _promptBiometricAndNavigate() async {
    if (_biometricPrompted) return;
    _biometricPrompted = true;

    final secureStorage = sl<SecureStorageService>();
    final biometricService = sl<BiometricService>();

    final biometricEnabled = await secureStorage.isBiometricEnabled();
    if (!biometricEnabled) {
      _navigateHome();
      return;
    }

    final canCheck = await biometricService.canCheckBiometrics;
    if (!canCheck) {
      _navigateHome();
      return;
    }

    final didAuthenticate = await biometricService.authenticate(
      reason: 'Authenticate to unlock TaskFlow',
    );

    if (!mounted) return;

    if (didAuthenticate) {
      _navigateHome();
    } else {
      context.go(AppConstants.routeLogin);
    }
  }

  void _navigateHome() {
    if (!mounted) return;
    context.go(AppConstants.routeHome);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionCubit, SessionState>(
      listener: (context, state) {
        if (state is SessionAuthenticated) {
          _promptBiometricAndNavigate();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'TaskFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Project Management',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
