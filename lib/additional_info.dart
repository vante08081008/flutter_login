import 'package:flutter/material.dart';

class AdditionalInfo {
  AdditionalInfo({
    required this.label,
    required this.controller,
    required this.focusNode,
    this.onChanged,
    this.validator,
    this.iconData,
  });

  final String? label;
  final FormFieldValidator<String>? validator;
  final IconData? iconData;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
}
