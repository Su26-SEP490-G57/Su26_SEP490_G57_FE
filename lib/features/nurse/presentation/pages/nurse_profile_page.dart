import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poms/features/auth/domain/models/user_model.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';

/// Không dùng Scaffold — NurseShell đã cung cấp.
class NurseProfilePage extends ConsumerWidget {
  const NurseProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFFAF8FF),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E5E0))),
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tài khoản',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191B24),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Content
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDAE1FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 44,
                    color: Color(0xFF0050CB),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? user?.username ?? 'Điều dưỡng',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191B24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user?.primaryRole.displayName ?? 'Điều dưỡng'} • Khoa Ngoại Tiêu Hóa',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF424656),
                  ),
                ),
                const SizedBox(height: 32),
                _ProfileInformationCard(user: user),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(authNotifierProvider.notifier).signOut(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBA1A1A),
                        side: const BorderSide(color: Color(0xFFBA1A1A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileInformationCard extends StatelessWidget {
  const _ProfileInformationCard({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E5E0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              _ProfileInfoTile(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: user?.phoneNumber,
              ),

              const Divider(height: 32),

              _ProfileInfoTile(
                icon: Icons.cake_outlined,
                label: 'Ngày sinh',
                value: user?.formattedDob,
              ),

              const Divider(height: 32),

              _ProfileInfoTile(
                icon: Icons.location_on_outlined,
                label: 'Địa chỉ',
                value: user?.fullAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: const Color(0xFF2D7FF9)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF8B8D97),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? 'Chưa cập nhật',
                style: TextStyle(
                  color: value == null ? Colors.grey : const Color(0xFF1D1D1F),
                  fontStyle: value == null
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
