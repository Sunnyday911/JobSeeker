import 'package:flutter/material.dart';
import 'package:jobseeker/core/constants.dart';

/// Industry selector that lets the user pick from [kIndustries] **or type their
/// own** when none fits: choosing "Other" reveals a free-text field, and the
/// typed value is what gets stored. Emits the effective industry (custom text
/// when "Other" is chosen), or `null` when nothing valid is selected yet.
///
/// Handles round-tripping: if [initial] is a value not in [kIndustries] (a
/// previously-saved custom industry), the dropdown shows "Other" with the text
/// pre-filled.
class IndustryPicker extends StatefulWidget {
  final String? initial;
  final ValueChanged<String?> onChanged;

  /// When non-null, shown as the dropdown's `labelText`. Leave null if the
  /// screen already renders its own heading above the field.
  final String? label;

  const IndustryPicker({
    super.key,
    this.initial,
    required this.onChanged,
    this.label,
  });

  @override
  State<IndustryPicker> createState() => _IndustryPickerState();
}

class _IndustryPickerState extends State<IndustryPicker> {
  static const _customOption = 'Other';
  String? _selected; // the dropdown value (a kIndustries entry)
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null && init.isNotEmpty) {
      if (kIndustries.contains(init) && init != _customOption) {
        _selected = init;
      } else {
        // A custom value not in the list → represent it as "Other" + prefill.
        _selected = _customOption;
        _customCtrl.text = init;
      }
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    if (_selected == _customOption) {
      final t = _customCtrl.text.trim();
      widget.onChanged(t.isEmpty ? null : t);
    } else {
      widget.onChanged(_selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = _selected == _customOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selected,
          isExpanded: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: widget.label,
            hintText: 'Pilih industri',
          ),
          items: kIndustries
              .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                        i == _customOption ? 'Lainnya (tulis sendiri)' : i),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() => _selected = v);
            _emit();
          },
        ),
        if (isCustom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Tulis industri Anda',
            ),
            onChanged: (_) => _emit(),
          ),
        ],
      ],
    );
  }
}
