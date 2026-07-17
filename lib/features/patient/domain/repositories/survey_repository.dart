import 'package:poms/features/patient/domain/models/survey_models.dart';

abstract interface class SurveyRepository {
  Future<List<SurveyQuestion>> getQuestions();
  Future<SurveySubmitResult> submitSurvey(SurveySubmitRequest request);
  Future<SurveySubmitResult> getSurveyById(int surveyId);
}
