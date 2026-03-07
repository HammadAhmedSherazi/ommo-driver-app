part of 'custom_widget.dart';

class CustomTextfieldWidget extends StatefulWidget {
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
  final VoidCallback? onEditingComplete;
  final bool readOnly;
  final bool autoFocus;
  const CustomTextfieldWidget({
    super.key,
    this.readOnly = false,
    this.autoFocus = false,
    this.onEditingComplete,

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
  State<CustomTextfieldWidget> createState() => _CustomTextfieldWidgetState();
}

class _CustomTextfieldWidgetState extends State<CustomTextfieldWidget> {
  final ValueNotifier<bool> hasValue = ValueNotifier(false);
  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      widget.focusNode?.addListener(() {
        hasValue.value = widget.focusNode!.hasFocus
            ? (widget.controller?.text.isNotEmpty ?? false)
            : false;

        Helpers.print("hasValue ${hasValue.value}");
      });
      widget.controller?.addListener(() {
        hasValue.value = widget.focusNode!.hasFocus
            ? (widget.controller?.text.isNotEmpty ?? false)
            : false;
        Helpers.print("hasValue ${hasValue.value}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.readOnly,
      child: TextFormField(
        onTapOutside: widget.onTapOutside,
        onEditingComplete: () {
          FocusScope.of(context).unfocus();
          if (widget.onEditingComplete != null) widget.onEditingComplete!();
        },

        autofocus: widget.autoFocus,
        onChanged: widget.onChanged,
        focusNode: widget.focusNode,
        onTap: widget.onTap,
        controller: widget.controller,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        inputFormatters:
            widget.inputFormatters ??
            [
              if (widget.keyboardType == TextInputType.number)
                FilteringTextInputFormatter.digitsOnly, // only 0-9 allowed
            ],
        readOnly: widget.readOnly,
        decoration: InputDecoration(
          prefixIcon: widget.prefixIcon != null
              ? Row(children: [10.w, widget.prefixIcon!])
              : null,
          prefixIconConstraints: BoxConstraints(maxWidth: 40, maxHeight: 24),
          suffixIconConstraints: BoxConstraints(maxWidth: 40, maxHeight: 24),
          suffixIcon:
              // widget.suffixIcon ??
              Row(
                children: [
                  ValueListenableBuilder(
                    valueListenable: hasValue,
                    builder: (_, showClear, c) {
                      Helpers.print(showClear);
                      if (showClear) {
                        return IconButton(
                          onPressed: () {
                            widget.controller?.clear();
                          },
                          icon: Icon(
                            Icons.cancel,
                            color: AppColorTheme().primary,
                          ),
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(EdgeInsets.zero),
                            visualDensity: VisualDensity(
                              horizontal: -4.0,
                              vertical: -4.0,
                            ),
                          ),
                        );
                      } else {
                        return widget.suffixIcon ?? SizedBox.shrink();
                      }
                    },
                  ),
                  // 10.w
                ],
              ),
          hintText: widget.hintText,
          filled: true,
          fillColor: 
          // widget.readOnly
          //     ? Colors.transparent
          //     :
               AppColorTheme().whiteShade,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
