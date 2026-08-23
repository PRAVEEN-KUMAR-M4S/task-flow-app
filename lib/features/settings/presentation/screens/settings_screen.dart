import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/network/connectivity_cubit.dart';
import 'package:task_flow/core/services/biometric_service.dart';
import 'package:task_flow/core/storage/secure_storage_service.dart';
import 'package:task_flow/core/theme/theme_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricLabel = 'Checking...';

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final secureStorage = sl<SecureStorageService>();
    final biometricService = sl<BiometricService>();

    final canCheck = await biometricService.canCheckBiometrics;
    final deviceSupported = await biometricService.isDeviceSupported;
    final enabled = await secureStorage.isBiometricEnabled();
    final types = await biometricService.availableBiometrics;
    final label = biometricService.biometricLabel(types);

    if (!mounted) return;
    setState(() {
      _biometricAvailable = canCheck || deviceSupported;
      _biometricEnabled = enabled;
      _biometricLabel = label;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final secureStorage = sl<SecureStorageService>();
    final biometricService = sl<BiometricService>();

    if (value) {
      // User wants to enable — prompt for biometric to confirm identity.
      final didAuthenticate = await biometricService.authenticate(
        reason: 'Authenticate to enable biometric unlock',
      );
      if (!didAuthenticate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication failed. Feature not enabled.')),
        );
        return;
      }
    }

    await secureStorage.setBiometricEnabled(enabled: value);
    if (!mounted) return;
    setState(() => _biometricEnabled = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Biometric unlock enabled' : 'Biometric unlock disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeCubit = context.watch<ThemeCubit>();
    final isDarkMode = themeCubit.state == ThemeMode.dark;

    final connectivityCubit = context.watch<ConnectivityCubit>();
    final isOffline = connectivityCubit.state.isOffline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _sectionHeader(context, 'Appearance'),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(isDarkMode ? 'Dark UI enabled' : 'Light UI enabled'),
              value: isDarkMode,
              onChanged: (val) => context.read<ThemeCubit>().toggleTheme(),
            ),
          ),
          const SizedBox(height: 20),

          // Security Section
          _sectionHeader(context, 'Security'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    _biometricAvailable
                        ? Icons.fingerprint_rounded
                        : Icons.lock_outline_rounded,
                    color: _biometricAvailable
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  title: const Text('Biometric Unlock'),
                  subtitle: Text(
                    !_biometricAvailable
                        ? 'Not available on this device'
                        : _biometricEnabled
                            ? 'Enabled ($_biometricLabel)'
                            : 'Unlock with $_biometricLabel',
                  ),
                  value: _biometricEnabled,
                  onChanged: _biometricAvailable ? _toggleBiometric : null,
                ),
                if (_biometricAvailable && !_biometricEnabled) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'When enabled, you\'ll need to verify your identity with $_biometricLabel each time you open the app with an active session.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Simulation & Debug Section
          _sectionHeader(context, 'Debug & Simulation'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                    color: isOffline ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                  title: const Text('Simulate Offline Mode'),
                  subtitle: const Text('Forces database repositories to use offline cached data'),
                  value: isOffline,
                  onChanged: (val) {
                    if (val) {
                      context.read<ConnectivityCubit>().setOffline();
                    } else {
                      context.read<ConnectivityCubit>().setOnline();
                    }
                  },
                ),
                const Divider(),
                ExpansionTile(
                  leading: Icon(Icons.bug_report_outlined, color: theme.colorScheme.primary),
                  title: const Text('Error Trigger Guide'),
                  subtitle: const Text('Learn how to trigger deterministic error states'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To test error-handling UI and state rendering, you can enter specific suffixes in task IDs, project names, or search descriptions:',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          _errorItem(
                            theme,
                            'Simulated 404 (Not Found)',
                            'Contains "_err404" (e.g. task_err404)',
                            'Throws a NotFoundException and displays error-state widgets with retry.',
                          ),
                          const SizedBox(height: 8),
                          _errorItem(
                            theme,
                            'Simulated Timeout',
                            'Contains "_errTimeout" (e.g. task_errTimeout)',
                            'Throws a TimeoutException and tests connection timeout handlers.',
                          ),
                          const SizedBox(height: 8),
                          _errorItem(
                            theme,
                            'Simulated Validation Error',
                            'Contains "_errValidation"',
                            'Throws a ValidationException and surfaces inline form/action errors.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About Section
          _sectionHeader(context, 'About'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _AboutRow(label: 'App Name', value: 'TaskFlow'),
                  Divider(height: 24),
                  _AboutRow(label: 'Version', value: '1.0.0 (Build 1)'),
                  Divider(height: 24),
                  _AboutRow(label: 'Architecture', value: 'Clean + BLoC/Cubit'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _errorItem(ThemeData theme, String title, String code, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              code,
              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
