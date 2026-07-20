import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/operation_type_remote_datasource.dart';
import '../../data/repositories/operation_type_repository_impl.dart';
import '../../domain/models/operation_type.dart';
import '../../domain/repositories/operation_type_repository.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';

enum OperationTypeStatus {
  initial,
  loading,
  loaded,
  error,
}

class OperationTypeState {
  const OperationTypeState({
    this.status = OperationTypeStatus.initial,
    this.operationTypes = const [],
    this.errorMessage,
  });

  final OperationTypeStatus status;
  final List<OperationType> operationTypes;
  final String? errorMessage;

  OperationTypeState copyWith({
    OperationTypeStatus? status,
    List<OperationType>? operationTypes,
    String? errorMessage,
  }) {
    return OperationTypeState(
      status: status ?? this.status,
      operationTypes: operationTypes ?? this.operationTypes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OperationTypeNotifier
    extends StateNotifier<OperationTypeState> {

  OperationTypeNotifier(this._repository)
      : super(const OperationTypeState()) {
    loadOperationTypes();
  }

  final OperationTypeRepository _repository;

  Future<void> loadOperationTypes() async {
    state = state.copyWith(
      status: OperationTypeStatus.loading,
    );

    try {
      final operationTypes =
          await _repository.getOperationTypes();

      state = state.copyWith(
        status: OperationTypeStatus.loaded,
        operationTypes: operationTypes,
      );
    } catch (e) {
      state = state.copyWith(
        status: OperationTypeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final operationTypeRemoteDatasourceProvider =
    Provider<OperationTypeRemoteDatasource>((ref) {
  return OperationTypeRemoteDatasourceImpl(
    ref.read(appDioProvider),
  );
});

final operationTypeRepositoryProvider =
    Provider<OperationTypeRepository>((ref) {
  return OperationTypeRepositoryImpl(
    ref.read(operationTypeRemoteDatasourceProvider),
  );
});

final operationTypeNotifierProvider =
    StateNotifierProvider<
        OperationTypeNotifier,
        OperationTypeState>((ref) {
  return OperationTypeNotifier(
    ref.read(operationTypeRepositoryProvider),
  );
});