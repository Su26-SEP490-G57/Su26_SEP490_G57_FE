class OperationTypeResponse {
  const OperationTypeResponse({
    required this.id,
    required this.name,
  });

  factory OperationTypeResponse.fromJson(Map<String, dynamic> json) {
    return OperationTypeResponse(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}