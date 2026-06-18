import 'package:flutter/material.dart';

/// Không dùng Scaffold — NurseShell đã cung cấp.
class NurseTasksPage extends StatelessWidget {
  const NurseTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tasks — Coming soon',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Color(0xFF424656),
        ),
      ),
    );
  }
}
