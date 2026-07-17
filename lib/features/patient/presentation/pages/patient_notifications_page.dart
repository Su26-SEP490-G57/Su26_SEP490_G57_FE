import 'package:flutter/material.dart';

import 'package:poms/core/constants/app_colors.dart';

class PatientNotificationsPage extends StatelessWidget {
  const PatientNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Thông báo — Coming soon',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
