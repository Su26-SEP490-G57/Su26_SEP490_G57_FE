import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PatientDashboardPage extends ConsumerWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          AppButton(
            label: AppStrings.logout,
            variant: AppButtonVariant.text,
            minimumSize: const Size(80, 40),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'Xin chào, ${user?.displayName ?? user?.email ?? 'Bệnh nhân'}',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Patient Dashboard — Coming soon',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
