import 'package:flutter/material.dart';

class PatientPagination extends StatelessWidget {
  const PatientPagination({
    required this.currentPage, required this.totalPages, required this.startIndex, required this.endIndex, required this.total, required this.onPrevious, required this.onNext, super.key,
  });

  final int currentPage;
  final int totalPages;
  final int startIndex;
  final int endIndex;
  final int total;

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2C6D8)),
      ),
      child: Column(
        children: [
          Text(
            'Hiển thị $startIndex–$endIndex / $total người bệnh',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: currentPage > 1 ? onPrevious : null,
                icon: const Icon(Icons.chevron_left),
              ),

              Text(
                '$currentPage / $totalPages',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(
                onPressed: currentPage < totalPages ? onNext : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
