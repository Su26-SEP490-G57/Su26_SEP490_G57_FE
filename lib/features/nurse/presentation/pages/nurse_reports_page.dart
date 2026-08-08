import 'package:flutter/material.dart';

class NurseReportsPage extends StatelessWidget {
  const NurseReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Báo cáo',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Color(0xFF424656),
        ),
      ),
    );
  }
}
