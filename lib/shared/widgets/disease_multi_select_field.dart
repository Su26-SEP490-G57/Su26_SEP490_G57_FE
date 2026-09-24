import 'package:flutter/material.dart';

import 'package:poms/core/constants/disease_catalog.dart';

/// Chọn nhiều bệnh từ danh mục ICD — tương đương `DiseaseAutocomplete
/// multiple` của web: các bệnh đã chọn hiển thị dạng chip (có nút xoá), ô bên
/// dưới tìm theo mã hoặc tên (không dấu cũng được).
class DiseaseMultiSelectField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final selected = values.toSet();

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
          optionsBuilder: (textEditingValue) {
            final query = _normalize(textEditingValue.text);
            return diseaseCatalog.where(
              (option) =>
                  !selected.contains(option.label) &&
                  _normalize('${option.code} ${option.name}').contains(query),
            );
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

// Bỏ dấu tiếng Việt để tìm "tang huyet ap" vẫn ra "Tăng huyết áp".
String _normalize(String value) {
  const from =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const to =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index >= 0 ? to[index] : char);
  }
  return buffer.toString();
}
