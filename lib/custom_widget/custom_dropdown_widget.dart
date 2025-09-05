part of 'custom_widget.dart';

class CustomDropDown<T> extends StatelessWidget {
  const CustomDropDown({
    super.key,
    this.options = const [],
    this.value,
    this.expandIcon,
    this.onChanged,
    this.isDense = true,
    this.filled = false,
    this.fillColor,
    this.dropdownColor,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.disabledBorder,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.contentPadding,
    this.placeholderText,
    this.placeholderStyle,
    this.expandIconColor,
    this.error,
  });

  final List<CustomDropDownOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final Widget? expandIcon;
  final bool? isDense;
  final bool? filled;
  final Color? fillColor;
  final Color? dropdownColor;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final InputBorder? disabledBorder;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final EdgeInsetsGeometry? contentPadding;
  final String? placeholderText;
  final TextStyle? placeholderStyle;
  final Color? expandIconColor;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: false,
      dropdownColor: dropdownColor ?? AppColorTheme().white,
      borderRadius: BorderRadius.circular(16),

      icon:
          expandIcon ??
          Icon(
            Icons.arrow_drop_down,
            color: expandIconColor ?? AppColorTheme().grey,
          ),
      hint: Text(
        placeholderText ?? 'Select',
        style:
            placeholderStyle ??
            AppTextTheme().bodyText.copyWith(
              color: AppColorTheme().black.withValues(alpha: 0.4),
            ),
      ),
      items:
          options.map((option) {
            return DropdownMenuItem(
              value: option.value,

              child: Text(
                option.displayOption,
                style: AppTextTheme().bodyText.copyWith(
                  color: AppColorTheme().black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
      decoration:  InputDecoration(
                                
                                prefixIcon:prefixIcon != null ? Row(
                                  children: [
                                    10.w,
                                    prefixIcon!,
                                  ],
                                ) : null,
                                prefixIconConstraints: BoxConstraints(
                                  maxWidth: 40,
                                  maxHeight: 24
                                ),
                                suffixIconConstraints: BoxConstraints(
                                  maxWidth: 40,
                                  maxHeight: 24
                                ),
                                suffixIcon: suffixIcon != null ? Row(
                                  children: [
                                    suffixIcon!,
                                    // 10.w
                                  ],
                                ) : null,
                                hintText: placeholderText,
                                filled: true,
                                fillColor: AppColorTheme().whiteShade,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ), style: AppTextTheme().bodyText,
      value: value,
      onChanged: onChanged,
    );
  }
}

class CustomDropDownOption<T> {
  final T value;
  final String displayOption;

  const CustomDropDownOption({
    required this.value,
    required this.displayOption,
  });
}