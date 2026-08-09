/// Bảng đánh giá cuối ngày của 1 bệnh nhân — câu hỏi triệu chứng x POD.
class AssessmentMatrixCell {
  const AssessmentMatrixCell({required this.pod, required this.score});

  final int pod;
  final int? score;
}

class AssessmentMatrixQuestion {
  const AssessmentMatrixQuestion({
    required this.questionId,
    required this.questionText,
    required this.cells,
  });

  final int questionId;
  final String questionText;
  final List<AssessmentMatrixCell> cells;

  int? scoreForPod(int pod) {
    for (final cell in cells) {
      if (cell.pod == pod) return cell.score;
    }
    return null;
  }
}

class AssessmentMatrix {
  const AssessmentMatrix({
    required this.caseId,
    required this.pods,
    required this.questions,
  });

  final String caseId;
  final List<int> pods;
  final List<AssessmentMatrixQuestion> questions;
}
