import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/shared/widgets/app_avatar.dart';
import 'package:task_flow/shared/widgets/confirm_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<SessionCubit>().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Not signed in'),
        ),
      );
    }

    // Map organization IDs to friendly names for UI display
    final orgName = user.orgId == 'org_a'
        ? 'Alpha Corp'
        : user.orgId == 'org_b'
            ? 'Beta Labs'
            : user.orgId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar
            Center(
              child: AppAvatar(
                imageUrl: user.avatarUrl,
                name: user.name,
                radius: 54,
              ),
            ),
            const SizedBox(height: 24),
            // Name & Job Title
            Center(
              child: Column(
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.roleLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.business_outlined,
                      label: 'Organization',
                      value: orgName,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.shield_outlined,
                      label: 'Role',
                      value: user.isAdmin ? 'Admin' : 'Member',
                      valueColor: user.isAdmin ? theme.colorScheme.primary : null,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member Since',
                      value: user.orgName,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Logout Button
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out? Your secure token session will be cleared.',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      context.read<SessionCubit>().logout();
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
