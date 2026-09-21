import 'package:flutter_test/flutter_test.dart';
import 'package:poms/features/doctor/domain/models/doctor_notification.dart';

void main() {
  group('DoctorNotification', () {
    test('keeps a manual nurse diet hold log', () {
      final json = <String, dynamic>{
        'logId': 1,
        'caseId': 'CASE-001',
        'patientName': 'Nguyễn Văn A',
        'roomBed': 'P.101/G.02',
        'holdReason': 'Người bệnh chưa dung nạp tốt.',
        'changedAt': '2026-09-21T09:00:00.000Z',
      };

      expect(DoctorNotification.isVisible(json), isTrue);
      final notification = DoctorNotification.fromJson(json);
      expect(notification.patientName, 'Nguyễn Văn A');
      expect(notification.roomBed, 'P.101/G.02');
    });

    test('excludes an automatic diet hold', () {
      final json = <String, dynamic>{
        'logId': 1,
        'caseId': 'CASE-001',
        'actionType': 'System_Auto',
      };

      expect(DoctorNotification.isVisible(json), isFalse);
    });

    test('excludes the existing handled-alert payload', () {
      final json = <String, dynamic>{
        'alertId': 12,
        'caseId': 'CASE-001',
        'alertType': 'RED',
        'handledAt': '2026-09-21T09:00:00.000Z',
      };

      expect(DoctorNotification.isVisible(json), isFalse);
    });
  });
}
