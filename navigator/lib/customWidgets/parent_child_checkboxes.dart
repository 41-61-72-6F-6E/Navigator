import 'package:flutter/material.dart';
import 'package:navigator/customWidgets/custom_labeled_checkbox.dart'; // Import your custom checkbox

class ParentChildCheckboxes extends StatefulWidget {
  final String parentLabel;
  final List<String> childrenLabels;
  final String? sectionTitle;
  final Color activeColor;
  final Function(bool?, List<bool>)? onSelectionChanged;
  final EdgeInsets? padding;
  final bool? initialParentValue;
  final List<bool>? initialChildrenValues;
  final Color textColor;

  const ParentChildCheckboxes({
    super.key,
    this.parentLabel = 'Select All',
    this.childrenLabels = const ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
    this.sectionTitle,
    this.activeColor = Colors.indigo,
    this.onSelectionChanged,
    this.padding,
    this.initialParentValue,
    this.initialChildrenValues,
    this.textColor = Colors.black
  }) : assert(
         initialChildrenValues == null || 
         initialChildrenValues.length == childrenLabels.length,
         'initialChildrenValues length must match childrenLabels length'
       );

  @override
  _ParentChildCheckboxesState createState() => _ParentChildCheckboxesState();
}

class _ParentChildCheckboxesState extends State<ParentChildCheckboxes> {
  bool? _parentValue;
  late List<String> _children;
  late List<bool> _childrenValue;

  @override
  void initState() {
    super.initState();
    _children = widget.childrenLabels;
    
    // Initialize children values
    if (widget.initialChildrenValues != null) {
      _childrenValue = List.from(widget.initialChildrenValues!);
    } else {
      _childrenValue = List.generate(_children.length, (index) => false);
    }
    
    // Initialize parent value based on children or provided value
    if (widget.initialParentValue != null) {
      _parentValue = widget.initialParentValue;
    } else {
      _updateParentValue();
    }
  }

  void _updateParentValue() {
    if (_childrenValue.every((value) => value == true)) {
      // All children selected
      _parentValue = true;
    } else if (_childrenValue.every((value) => value == false)) {
      // No children selected
      _parentValue = false;
    } else {
      // Some children selected (indeterminate state)
      _parentValue = null;
    }
  }

  void _checkAll(bool value) {
    setState(() {
      _parentValue = value;
      for (int i = 0; i < _children.length; i++) {
        _childrenValue[i] = value;
      }
    });
    
    // Notify parent widget about selection changes
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_parentValue, _childrenValue);
    }
  }

  void _manageTristate(int index, bool? value) {
    setState(() {
      if (value == true) {
        // selected
        _childrenValue[index] = true;
        // Checking if all other children are also selected
        if (_childrenValue.contains(false)) {
          // No. Parent -> tristate.
          _parentValue = null;
        } else {
          // Yes. Select all.
          _checkAll(true);
          return; // _checkAll already calls onSelectionChanged
        }
      } else {
        // unselected
        _childrenValue[index] = false;
        // Checking if all other children are also unselected
        if (_childrenValue.contains(true)) {
          // No. Parent -> tristate.
          _parentValue = null;
        } else {
          // Yes. Unselect all.
          _checkAll(false);
          return; // _checkAll already calls onSelectionChanged
        }
      }
    });
    
    // Notify parent widget about selection changes
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_parentValue, _childrenValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    
    return Container(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Section title (optional)
          if (widget.sectionTitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
              child: Text(
                widget.sectionTitle!,
                style: themeData.textTheme.titleMedium?.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            ),
          
          // Parent checkbox
          CustomLabeledCheckbox(
            label: widget.parentLabel,
            value: _parentValue??false,
            onChanged: (value) {
              _checkAll(value);
                        },
            checkboxType: CheckboxType.Parent,
            activeColor: widget.activeColor,
            textColor: widget.textColor,
          ),
          
          // Children checkboxes
          ...List.generate(
            _children.length,
            (index) => CustomLabeledCheckbox(
              textColor: widget.textColor,
              label: _children[index],
              value: _childrenValue[index],
              onChanged: (value) {
                _manageTristate(index, value);
              },
              checkboxType: CheckboxType.Child,
              activeColor: widget.activeColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods to get current state
  bool? get parentValue => _parentValue;
  List<bool> get childrenValues => List.from(_childrenValue);
  List<String> get selectedChildren {
    List<String> selected = [];
    for (int i = 0; i < _children.length; i++) {
      if (_childrenValue[i]) {
        selected.add(_children[i]);
      }
    }
    return selected;
  }
}