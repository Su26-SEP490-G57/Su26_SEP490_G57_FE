import 'package:poms/core/utils/exception_handler.dart';
import 'package:poms/features/patient/domain/models/survey_models.dart';
import 'package:poms/features/patient/domain/repositories/survey_repository.dart';
import 'package:poms/features/patient/data/datasources/survey_remote_datasource.dart';

class SurveyRepositoryImpl implements SurveyRepository {
  SurveyRepositoryImpl(this._dataSource);

  final SurveyRemoteDataSource _dataSource;

  @override
  Future<List<SurveyQuestion>> getQuestions() async {
    try {
      return await _dataSource.getQuestions();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<SurveySubmitResult> submitSurvey(SurveySubmitRequest request) async {
    try {
      return await _dataSource.submitSurvey(request);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<SurveySubmitResult> getSurveyById(int surveyId) async {
    try {
      return await _dataSource.getSurveyById(surveyId);
    } catch (e) {
      throw mapException(e);
    }
  }
}
