/// Danh mục bệnh (ICD) — BẢN SAO của
/// `Su26_SEP490_G57_FE_ADMIN/src/features/patients/diseaseCatalog.ts`, để
/// "Bệnh kèm theo" trên mobile lưu đúng cùng nhãn `CODE - Tên` như form thêm
/// người bệnh trên web. Sửa danh mục thì sửa cả hai nơi.
class DiseaseOption {
  const DiseaseOption({required this.code, required this.name});

  final String code;
  final String name;

  String get label => '$code - $name';
}

const List<DiseaseOption> diseaseCatalog = [
  DiseaseOption(
    code: 'A00.1',
    name: 'Bệnh tả do Vibrio cholerae, típ sinh học cholerae',
  ),
  DiseaseOption(code: 'C16.9', name: 'Ung thư dạ dày, không xác định'),
  DiseaseOption(code: 'C18.9', name: 'Ung thư đại tràng, không xác định'),
  DiseaseOption(code: 'C20', name: 'Ung thư trực tràng'),
  DiseaseOption(
    code: 'K25.4',
    name: 'Loét dạ dày mạn tính hoặc không xác định có xuất huyết',
  ),
  DiseaseOption(
    code: 'K26.4',
    name: 'Loét tá tràng mạn tính hoặc không xác định có xuất huyết',
  ),
  DiseaseOption(code: 'K35.8', name: 'Viêm ruột thừa cấp khác'),
  DiseaseOption(code: 'K40.9', name: 'Thoát vị bẹn, không nghẹt hoặc hoại tử'),
  DiseaseOption(code: 'K56.6', name: 'Tắc ruột khác và không xác định'),
  DiseaseOption(
    code: 'K57.3',
    name: 'Bệnh túi thừa đại tràng không có thủng hoặc áp xe',
  ),
  DiseaseOption(code: 'K60.3', name: 'Rò hậu môn'),
  DiseaseOption(code: 'K61.0', name: 'Áp xe hậu môn'),
  DiseaseOption(code: 'K63.1', name: 'Thủng ruột (không do chấn thương)'),
  DiseaseOption(code: 'K80.2', name: 'Sỏi túi mật không có viêm túi mật'),
  DiseaseOption(code: 'K81.0', name: 'Viêm túi mật cấp'),
  DiseaseOption(code: 'K85.9', name: 'Viêm tụy cấp, không xác định'),
  DiseaseOption(code: 'K86.1', name: 'Viêm tụy mạn khác'),
  DiseaseOption(code: 'N20.0', name: 'Sỏi thận'),
  DiseaseOption(code: 'N40', name: 'Tăng sản tuyến tiền liệt'),
  DiseaseOption(code: 'N80.9', name: 'Lạc nội mạc tử cung, không xác định'),
];
