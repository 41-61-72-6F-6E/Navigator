import 'package:flutter/material.dart';

enum CheckboxType {
  Parent,
  Child,
}

@immutable
class CustomLabeledCheckbox extends StatelessWidget {
  const CustomLabeledCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    this.checkboxType = CheckboxType.Child,
    required this.activeColor,
  })  : assert(label != null),
        assert(checkboxType != null),
        assert(
          (checkboxType == CheckboxType.Child && value != null) ||
              checkboxType == CheckboxType.Parent,
        ),
        tristate = checkboxType == CheckboxType.Parent ? true : false;

  final String label;
  final bool value;
  final bool tristate;
  final ValueChanged<bool> onChanged;
  final CheckboxType checkboxType;
  final Color activeColor;

  void _onChanged() {
    if (value != null) {
      onChanged(!value);
    } else {
      onChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return InkWell(
      onTap: _onChanged,
      child: Row(
        children: <Widget>[
          checkboxType == CheckboxType.Parent
              ? SizedBox(width: 0)
              : SizedBox(width: 32),
          Checkbox(
            tristate: tristate,
            value: value,
            onChanged: (_) {
              _onChanged();
            },
            activeColor: activeColor,
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: themeData.textTheme.bodyMedium,
          )
        ],
      ),
    );
  }
}