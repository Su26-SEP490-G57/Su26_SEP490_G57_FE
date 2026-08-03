class PodHealthEducation {
  const PodHealthEducation({
    required this.podNumber,
    required this.podTitle,
    required this.podSubtitle,
    required this.phaseName,
    required this.goals,
    required this.actions,
    required this.warningHeader,
    required this.warnings,
    required this.note,
  });

  final int podNumber;
  final String podTitle;
  final String podSubtitle;
  final String phaseName;
  final List<String> goals;
  final List<String> actions;
  final String warningHeader;
  final List<String> warnings;
  final String note;
}

const List<PodHealthEducation> podHealthEducationData = [
  // ── POD 0 ──────────────────────────────────────────────────────────────────
  PodHealthEducation(
    podNumber: 0,
    podTitle: 'POD0',
    podSubtitle: '0–24 giờ sau phẫu thuật',
    phaseName: 'GIAI ĐOẠN I: HỒI PHỤC SỚM (POD0 → POD4)',
    goals: [
      'Ổn định sau phẫu thuật.',
      'Khởi động quá trình hồi phục.',
      'Phòng ngừa biến chứng hô hấp và tuần hoàn.',
    ],
    actions: [
      'Thay đổi tư thế trên giường theo hướng dẫn.',
      'Ngồi dậy hoặc nâng đầu giường nếu được phép.',
      'Tập hít sâu và thở chậm nhiều lần trong ngày.',
      'Ho khạc đờm đúng cách nếu có đờm.',
    ],
    warningHeader: 'Báo điều dưỡng ngay nếu',
    warnings: [
      'Khó thở.',
      'Đau tăng nhiều.',
      'Nôn liên tục.',
      'Chảy máu.',
      'Choáng hoặc vã mồ hôi nhiều.',
    ],
    note:
        'Mỗi người hồi phục với tốc độ khác nhau. Hãy phối hợp với nhân viên y tế để quá trình hồi phục diễn ra an toàn.',
  ),

  // ── POD 1 ──────────────────────────────────────────────────────────────────
  PodHealthEducation(
    podNumber: 1,
    podTitle: 'POD1',
    podSubtitle: '24–48 giờ sau phẫu thuật',
    phaseName: 'GIAI ĐOẠN I: HỒI PHỤC SỚM (POD0 → POD4)',
    goals: [
      'Tăng vận động.',
      'Tiếp tục phòng biến chứng.',
      'Làm quen với chế độ ăn theo hướng dẫn.',
    ],
    actions: [
      'Ngồi ghế và đi lại ngắn nhiều lần trong ngày.',
      'Tiếp tục tập hít sâu và ho khạc đờm.',
      'Uống đủ nước theo hướng dẫn.',
      'Dùng thuốc đúng giờ.',
      'Giữ băng vết mổ sạch và khô.',
    ],
    warningHeader: 'Báo điều dưỡng ngay nếu',
    warnings: [
      'Nôn nhiều.',
      'Đau bụng tăng.',
      'Bụng chướng nhiều.',
      'Sốt ≥38°C.',
      'Chảy dịch bất thường tại vết mổ.',
    ],
    note:
        'Không tự ý thay đổi chế độ ăn nếu chưa có hướng dẫn của bác sĩ hoặc điều dưỡng.',
  ),

  // ── POD 2 ──────────────────────────────────────────────────────────────────
  PodHealthEducation(
    podNumber: 2,
    podTitle: 'POD2',
    podSubtitle: '48–72 giờ sau phẫu thuật',
    phaseName: 'GIAI ĐOẠN I: HỒI PHỤC SỚM (POD0 → POD4)',
    goals: [
      'Tiếp tục hồi phục chức năng tiêu hóa.',
      'Tăng khả năng tự chăm sóc.',
      'Duy trì vận động.',
    ],
    actions: [
      'Đi lại nhiều lần trong ngày.',
      'Tiếp tục tập thở.',
      'Theo dõi trung tiện và đại tiện.',
      'Giữ vệ sinh cá nhân.',
      'Uống đủ nước theo hướng dẫn.',
    ],
    warningHeader: 'Báo điều dưỡng ngay nếu',
    warnings: [
      'Không ăn uống được.',
      'Nôn nhiều.',
      'Bụng chướng tăng.',
      'Đau bụng nhiều.',
      'Sốt hoặc rét run.',
    ],
    note:
        'Việc hồi phục tiêu hóa ở mỗi người có thể khác nhau. Hãy tiếp tục thực hiện đúng hướng dẫn của nhân viên y tế.',
  ),

  // ── POD 3 ──────────────────────────────────────────────────────────────────
  PodHealthEducation(
    podNumber: 3,
    podTitle: 'POD3',
    podSubtitle: '72–96 giờ sau phẫu thuật',
    phaseName: 'GIAI ĐOẠN I: HỒI PHỤC SỚM (POD0 → POD4)',
    goals: ['Tăng mức độ độc lập trong sinh hoạt.', 'Duy trì vận động.'],
    actions: [
      'Đi bộ thường xuyên.',
      'Tự thực hiện các sinh hoạt cá nhân nếu có thể.',
      'Tiếp tục uống thuốc đúng hướng dẫn.',
      'Theo dõi vết mổ hằng ngày.',
      'Uống đủ nước.',
    ],
    warningHeader: 'Báo điều dưỡng ngay nếu',
    warnings: [
      'Đau tăng.',
      'Nôn nhiều.',
      'Sốt.',
      'Chảy dịch hoặc chảy máu vết mổ.',
      'Khó thở.',
    ],
    note:
        'Đừng so sánh tốc độ hồi phục của mình với người bệnh khác. Hãy tập trung vào mục tiêu hồi phục của chính bạn.',
  ),

  // ── POD 4 ──────────────────────────────────────────────────────────────────
  PodHealthEducation(
    podNumber: 4,
    podTitle: 'POD4',
    podSubtitle: '96–120 giờ sau phẫu thuật',
    phaseName: 'GIAI ĐOẠN I: HỒI PHỤC SỚM (POD0 → POD4)',
    goals: ['Tăng khả năng tự chăm sóc.', 'Hiểu rõ hướng dẫn sau xuất viện.'],
    actions: [
      'Tiếp tục vận động hằng ngày.',
      'Dùng thuốc đúng đơn.',
      'Theo dõi vết mổ.',
      'Trao đổi với điều dưỡng nếu còn thắc mắc.',
    ],
    warningHeader: 'Báo điều dưỡng ngay nếu',
    warnings: [
      'Không ăn uống được.',
      'Đau tăng.',
      'Sốt.',
      'Chảy máu hoặc chảy mủ.',
      'Khó thở.',
    ],
    note:
        'Tiếp tục tuân thủ hướng dẫn điều trị và không tự ý thay đổi chế độ ăn.',
  ),

  // ── POD 5 ──────────────────────────────────────────────────────────────────
  PodHealthEducation(
    podNumber: 5,
    podTitle: 'POD5',
    podSubtitle: 'Ngày 5 sau phẫu thuật',
    phaseName: 'GIAI ĐOẠN II: TIẾP TỤC HỒI PHỤC (POD5 → POD7)',
    goals: ['Duy trì hồi phục.', 'Tăng khả năng tự chăm sóc.'],
    actions: [
      'Đi bộ nhiều lần trong ngày.',
      'Duy trì tập thở.',
      'Thực hiện đúng chế độ ăn hiện tại.',
      'Uống đủ nước.',
      'Nghỉ ngơi hợp lý.',
    ],
    warningHeader: 'Cần liên hệ nhân viên y tế nếu',
    warnings: [
      'Đau tăng.',
      'Sốt.',
      'Nôn.',
      'Bụng chướng nhiều.',
      'Chảy dịch bất thường.',
    ],
    note:
        'Tiếp tục tuân thủ hướng dẫn điều trị và không tự ý thay đổi chế độ ăn.',
  ),

  // ── POD 6 ──────────────────────────────────────────────────────────────────
  PodHealthEducation(
    podNumber: 6,
    podTitle: 'POD6',
    podSubtitle: 'Ngày 6 sau phẫu thuật',
    phaseName: 'GIAI ĐOẠN II: TIẾP TỤC HỒI PHỤC (POD5 → POD7)',
    goals: ['Tăng sức bền.', 'Chuẩn bị trở lại sinh hoạt thường ngày.'],
    actions: [
      'Duy trì vận động.',
      'Theo dõi vết mổ.',
      'Uống thuốc đúng hướng dẫn.',
      'Thực hiện đúng lịch tái khám nếu đã được hẹn.',
    ],
    warningHeader: 'Cần liên hệ nhân viên y tế nếu',
    warnings: [
      'Sốt ≥38°C.',
      'Đau bụng tăng.',
      'Chảy máu.',
      'Chảy mủ.',
      'Khó thở.',
    ],
    note: 'Không mang vác vật nặng và không lao động gắng sức.',
  ),

  // ── POD 7 ──────────────────────────────────────────────────────────────────
  PodHealthEducation(
    podNumber: 7,
    podTitle: 'POD7',
    podSubtitle: 'Ngày 7 sau phẫu thuật',
    phaseName: 'GIAI ĐOẠN II: TIẾP TỤC HỒI PHỤC (POD5 → POD7)',
    goals: ['Duy trì quá trình hồi phục.', 'Chủ động theo dõi sức khỏe.'],
    actions: [
      'Tiếp tục vận động phù hợp.',
      'Ăn đúng chế độ được hướng dẫn.',
      'Uống đủ nước.',
      'Theo dõi vết mổ hằng ngày.',
    ],
    warningHeader: 'Đến bệnh viện ngay nếu',
    warnings: [
      'Không ăn uống được.',
      'Nôn liên tục.',
      'Sốt ≥38°C.',
      'Đau bụng nhiều.',
      'Chảy dịch mủ hoặc chảy máu vết mổ.',
      'Khó thở.',
    ],
    note:
        'Nếu đã xuất viện, hãy tiếp tục tuân thủ đầy đủ hướng dẫn của bác sĩ và liên hệ cơ sở y tế khi có bất kỳ dấu hiệu bất thường nào.',
  ),
];
