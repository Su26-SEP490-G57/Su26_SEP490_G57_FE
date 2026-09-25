import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/shared/data/disease_search.dart';

/// Chọn nhiều bệnh từ danh mục ICD-10 (API /diseases) — tương đương
/// `DiseaseAutocomplete multiple` của web: các bệnh đã chọn hiển thị dạng chip
/// (có nút xoá), ô bên dưới tìm theo mã hoặc tên (không dấu cũng được).
class DiseaseMultiSelectField extends ConsumerWidget {
  const DiseaseMultiSelectField({
    required this.label,
    required this.values,
    required this.onChanged,
    this.enabled = true,
    this.decoration,
    super.key,
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  /// Decoration cho ô tìm kiếm; mặc định là outline có [label].
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = values.toSet();
    final diseaseSearch = DiseaseSearch(ref.read(appDioProvider));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (values.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values
                .map(
                  (value) => InputChip(
                    label: Text(value, overflow: TextOverflow.ellipsis),
                    labelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF1D4ED8),
                    ),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                    onDeleted: enabled
                        ? () => onChanged(
                            values.where((item) => item != value).toList(),
                          )
                        : null,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        Autocomplete<DiseaseOption>(
          displayStringForOption: (option) => option.label,
          optionsBuilder: (textEditingValue) async {
            try {
              final options = await diseaseSearch.search(textEditingValue.text);
              return options.where(
                (option) => !selected.contains(option.label),
              );
            } on Exception {
              return const Iterable<DiseaseOption>.empty();
            }
          },
          onSelected: (option) => onChanged([...values, option.label]),
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              decoration: (decoration ?? const InputDecoration()).copyWith(
                labelText: label,
                hintText: 'Tìm mã hoặc tên bệnh để thêm...',
                border:
                    decoration?.border ??
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: options
                        .map(
                          (option) => ListTile(
                            dense: true,
                            title: Text(option.label),
                            onTap: () => onSelected(option),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
