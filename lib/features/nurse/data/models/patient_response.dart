import 'package:equatable/equatable.dart';

class PatientListResponse extends Equatable {
  const PatientListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<PatientResponse> data;
  final int total;
  final int page;
  final int limit;

  factory PatientListResponse.fromJson(Map<String, dynamic> json) {
    return PatientListResponse(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => PatientResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
    };
  }

  @override
  List<Object?> get props => [data, total, page, limit];
}

class PatientResponse extends Equatable {
  const PatientResponse({
    required this.caseId,
    required this.age,
    required this.gender,
    required this.diagnosis,
    required this.roomBed,
    required this.currentPod,
    required this.bmi,
    required this.surgeryDate,
    required this.account,
    required this.operationType,
    required this.level,
    required this.method,
    required this.hasGiAnastomosis,
  });

  final String caseId;
  final int age;
  final String gender;
  final String? diagnosis;
  final String? method;
  final bool? hasGiAnastomosis;
  final String? roomBed;
  final int currentPod;
  final double? bmi;
  final String? surgeryDate;

  final AccountResponse account;
  final OperationTypeResponse? operationType;

  final dynamic level;

  factory PatientResponse.fromJson(Map<String, dynamic> json) {
    return PatientResponse(
      caseId: json['caseId'] as String,
      age: json['age'] as int? ?? 0,
      gender: json['gender'] as String? ?? '',
      diagnosis: json['diagnosis'] as String?,
      method: json['method'] as String?,
      hasGiAnastomosis: json['hasGiAnastomosis'] as bool?,
      roomBed: json['roomBed'] as String?,
      currentPod: json['currentPod'] as int? ?? 0,
      bmi: (json['bmi'] as num?)?.toDouble(),
      surgeryDate: json['surgeryDate'] as String?,
      account: AccountResponse.fromJson(
        json['account'] as Map<String, dynamic>,
      ),
      operationType: json['operationType'] == null
          ? null
          : OperationTypeResponse.fromJson(
              json['operationType'] as Map<String, dynamic>,
            ),
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caseId': caseId,
      'age': age,
      'gender': gender,
      'diagnosis': diagnosis,
      'method': method,
      'hasGiAnastomosis': hasGiAnastomosis,
      'roomBed': roomBed,
      'currentPod': currentPod,
      'bmi': bmi,
      'surgeryDate': surgeryDate,
      'account': account.toJson(),
      'operationType': operationType?.toJson(),
      'level': level,
    };
  }

  @override
  List<Object?> get props => [
    caseId,
    age,
    gender,
    diagnosis,
    method,
    hasGiAnastomosis,
    roomBed,
    currentPod,
    bmi,
    surgeryDate,
    account,
    operationType,
    level,
  ];
}

class AccountResponse extends Equatable {
  const AccountResponse({
    required this.id,
    required this.fullName,
    required this.username,
  });

  final int id;
  final String fullName;
  final String username;

  factory AccountResponse.fromJson(Map<String, dynamic> json) {
    return AccountResponse(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'fullName': fullName, 'username': username};
  }

  @override
  List<Object?> get props => [id, fullName, username];
}

class OperationTypeResponse extends Equatable {
  const OperationTypeResponse({required this.id, required this.name});

  final int id;
  final String name;

  factory OperationTypeResponse.fromJson(Map<String, dynamic> json) {
    return OperationTypeResponse(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  List<Object?> get props => [id, name];
}
