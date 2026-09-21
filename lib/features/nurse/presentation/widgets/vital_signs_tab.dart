import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/utils/extensions.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/domain/models/vital_signs_record.dart';
import 'package:poms/features/nurse/presentation/providers/vital_signs_provider.dart';
import 'package:poms/shared/widgets/app_text_field.dart';

/// Tab "Chỉ số" — lịch sử chỉ số sinh tồn (mới nhất trước) + biểu mẫu ghi nhận.
///
/// Người ghi nhận và thời điểm ghi nhận luôn do máy chủ gán; biểu mẫu chỉ hiển
/// thị tên người đang đăng nhập như thông tin tham khảo trước khi gửi.
class VitalSignsTab extends ConsumerStatefulWidget {
  const VitalSignsTab({required this.caseId, super.key});

  final String caseId;

  @override
  ConsumerState<VitalSignsTab> createState() => _VitalSignsTabState();
}

class _VitalSignsTabState extends ConsumerState<VitalSignsTab> {
  final _formKey = GlobalKey<FormState>();
  final _pulseController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _respiratoryController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _pulseController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _temperatureController.dispose();
    _respiratoryController.dispose();
    _spo2Controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Validators (thông báo tiếng Việt, khớp ngưỡng với backend) ────────────

  String? _validateInt(
    String? value, {
    required String label,
    required int min,
    required int max,
    required String unit,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $label';
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '$label phải là số nguyên';
    }

    if (parsed < min || parsed > max) {
      return '$label phải trong khoảng $min–$max $unit';
    }

    return null;
  }

  String? _validateTemperature(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập nhiệt độ';
    }

    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) {
      return 'Nhiệt độ phải là số';
    }

    if (parsed < 30.0 || parsed > 43.0) {
      return 'Nhiệt độ phải trong khoảng 30.0–43.0 °C';
    }

    return null;
  }

  String? _validateDiastolic(String? value) {
    final base = _validateInt(
      value,
      label: 'Huyết áp tâm trương',
      min: 30,
      max: 150,
      unit: 'mmHg',
    );
    if (base != null) return base;

    final systolic = int.tryParse(_systolicController.text.trim());
    final diastolic = int.tryParse(value!.trim());

    if (systolic != null && diastolic != null && systolic <= diastolic) {
      return 'Huyết áp tâm thu phải lớn hơn tâm trương';
    }

    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final note = _noteController.text.trim();

    final record = await ref
        .read(vitalSignsNotifierProvider(widget.caseId).notifier)
        .submit(
          pulseBpm: int.parse(_pulseController.text.trim()),
          bloodPressureSystolic: int.parse(_systolicController.text.trim()),
          bloodPressureDiastolic: int.parse(_diastolicController.text.trim()),
          temperatureCelsius: double.parse(
            _temperatureController.text.trim().replaceAll(',', '.'),
          ),
          respiratoryRate: int.parse(_respiratoryController.text.trim()),
          spo2Percent: int.parse(_spo2Controller.text.trim()),
          note: note.isEmpty ? null : note,
        );

    if (!mounted) return;

    if (record == null) {
      context.showTopToast(
        'Không thể lưu chỉ số sinh tồn. Vui lòng thử lại.',
        isError: true,
      );
      return;
    }

    _pulseController.clear();
    _systolicController.clear();
    _diastolicController.clear();
    _temperatureController.clear();
    _respiratoryController.clear();
    _spo2Controller.clear();
    _noteController.clear();
    _formKey.currentState?.reset();

    context.showTopToast('Đã ghi nhận chỉ số sinh tồn', isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vitalSignsNotifierProvider(widget.caseId));
    final currentUser =
        ref.watch(authNotifierProvider).user ??
        ref.watch(authStateProvider).valueOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 220),
      children: [
        // ── Lịch sử (mới nhất trước) ────────────────────────────────────
        const _SectionTitle('Lịch sử chỉ số'),
        const SizedBox(height: 10),
        if (state.isLoading && state.history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.history.isEmpty)
          _EmptyBox(
            message:
                state.errorMessage ??
                'Chưa có chỉ số sinh tồn nào được ghi nhận',
          )
        else
          ...state.history.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VitalSignsHistoryCard(record: record),
            ),
          ),

        const SizedBox(height: 24),

        // ── Biểu mẫu ghi nhận ────────────────────────────────────────────
        const _SectionTitle('Ghi nhận chỉ số mới'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC2C6D8)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _pulseController,
                  label: 'Mạch (lần/phút)',
                  hint: '30 – 220',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => _validateInt(
                    value,
                    label: 'Mạch',
                    min: 30,
                    max: 220,
                    unit: 'lần/phút',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _systolicController,
                        label: 'HA tâm thu (mmHg)',
                        hint: '60 – 250',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) => _validateInt(
                          value,
                          label: 'Huyết áp tâm thu',
                          min: 60,
                          max: 250,
                          unit: 'mmHg',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _diastolicController,
                        label: 'HA tâm trương (mmHg)',
                        hint: '30 – 150',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validateDiastolic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _temperatureController,
                  label: 'Nhiệt độ (°C)',
                  hint: '30.0 – 43.0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: _validateTemperature,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _respiratoryController,
                  label: 'Nhịp thở (lần/phút)',
                  hint: '4 – 60',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => _validateInt(
                    value,
                    label: 'Nhịp thở',
                    min: 4,
                    max: 60,
                    unit: 'lần/phút',
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _spo2Controller,
                  label: 'SpO2 (%)',
                  hint: '0 – 100',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => _validateInt(
                    value,
                    label: 'SpO2',
                    min: 0,
                    max: 100,
                    unit: '%',
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _noteController,
                  label: 'Ghi chú (không bắt buộc)',
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  minLines: 2,
                ),

                const SizedBox(height: 12),

                // Chỉ là thông tin tham khảo — máy chủ mới là nơi quyết định
                // người ghi nhận và thời điểm ghi nhận.
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 16,
                      color: Color(0xFF424656),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Người ghi nhận: ${currentUser?.fullName ?? '—'} '
                        '(thời điểm do hệ thống ghi nhận)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF424656),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isSubmitting ? null : _submit,
                    icon: state.isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      state.isSubmitting ? 'Đang lưu...' : 'Lưu chỉ số',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Color(0xFF424656),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2C6D8)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: Color(0xFF424656),
        ),
      ),
    );
  }
}

class _VitalSignsHistoryCard extends StatelessWidget {
  const _VitalSignsHistoryCard({required this.record});

  final VitalSignsRecord record;

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(record.recordedAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2C6D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_heart_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                timestamp,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191B24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _VitalChip(label: 'Mạch', value: '${record.pulseBpm} lần/phút'),
              _VitalChip(
                label: 'Huyết áp',
                value: '${record.bloodPressureLabel} mmHg',
              ),
              _VitalChip(
                label: 'Nhiệt độ',
                value: '${record.temperatureCelsius.toStringAsFixed(1)} °C',
              ),
              _VitalChip(
                label: 'Nhịp thở',
                value: '${record.respiratoryRate} lần/phút',
              ),
              _VitalChip(label: 'SpO2', value: '${record.spo2Percent} %'),
            ],
          ),
          if (record.note != null && record.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.note!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: Color(0xFF424656),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Ghi nhận bởi ${record.recordedByName ?? 'Không rõ'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF6B6F80),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  const _VitalChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF6B6F80),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF191B24),
          ),
        ),
      ],
    );
  }
}
