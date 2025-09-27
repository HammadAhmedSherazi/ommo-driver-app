part of 'custom_widget.dart';

class CustomTextfieldWidget extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final void Function(PointerDownEvent)? onTapOutside;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  const CustomTextfieldWidget({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.onTapOutside,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onTapOutside:
          onTapOutside ??
          (event) {
            FocusScope.of(context).unfocus();
          },
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
      },
      onChanged: onChanged,
      focusNode: focusNode,
      onTap: onTap,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters:
          inputFormatters ??
          [
            if (keyboardType == TextInputType.number)
              FilteringTextInputFormatter.digitsOnly, // only 0-9 allowed
          ],
      readOnly: onTap != null,
      decoration: InputDecoration(
        prefixIcon: prefixIcon != null
            ? Row(children: [10.w, prefixIcon!])
            : null,
        prefixIconConstraints: BoxConstraints(maxWidth: 40, maxHeight: 24),
        suffixIconConstraints: BoxConstraints(maxWidth: 40, maxHeight: 24),
        suffixIcon: suffixIcon != null
            ? Row(
                children: [
                  suffixIcon!,
                  // 10.w
                ],
              )
            : null,
        hintText: hintText,
        filled: true,
        fillColor: AppColorTheme().whiteShade,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
