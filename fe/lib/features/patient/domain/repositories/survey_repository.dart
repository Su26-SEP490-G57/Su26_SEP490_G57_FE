import '../models/survey_models.dart';

abstract interface class SurveyRepository {
  /// GET /symptom-surveys/questions
  Future<List<SurveyQuestion>> getQuestions();

  /// POST /symptom-surveys
  Future<SurveySubmitResult> submitSurvey(SurveySubmitRequest request);

  /// GET /symptom-surveys/:surveyId — kèm recommendation
  Future<SurveySubmitResult> getSurveyById(int surveyId);
}
