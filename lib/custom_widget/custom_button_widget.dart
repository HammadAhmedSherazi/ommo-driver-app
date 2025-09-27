part of 'custom_widget.dart';

class CustomButtonWidget extends StatelessWidget {
  final bool isLoad;
  final bool enabled;
  final String title;
  final bool? isRightSide;
  final Widget? icon;
  final VoidCallback onPressed;
  final Color? bgColor;
  final Color? textColor;
  const CustomButtonWidget({
    super.key,
    required this.title,
    this.isLoad = false,
    this.enabled = true,
    required this.onPressed,
    this.icon,
    this.isRightSide = false,
    this.bgColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Platform.isIOS
          ? CupertinoButton(
              color: (bgColor ?? AppColorTheme().primary).withValues(
                alpha: enabled ? 1 : 07,
              ),
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(30),
              onPressed: enabled ? onPressed : null,
              child: icon != null
                  ? Row(
                      spacing: 5,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isRightSide!) ?icon,
                        Text(
                          title,
                          style: AppTextTheme().bodyText.copyWith(
                            color: textColor ?? Colors.white,
                          ),
                        ),
                        if (isRightSide!) ?icon,
                      ],
                    )
                  : Text(
                      title,
                      style: AppTextTheme().bodyText.copyWith(
                        color: textColor ?? Colors.white,
                      ),
                    ),
            )
          : ElevatedButton(
              style: ButtonStyle(
                elevation: WidgetStatePropertyAll(0.0),
                backgroundColor: WidgetStatePropertyAll(
                  (bgColor ?? AppColorTheme().primary).withValues(
                    alpha: enabled ? 1 : 07,
                  ),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              onPressed: enabled ? onPressed : null,
              child: icon != null
                  ? Row(
                      spacing: 5,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        icon!,
                        Text(
                          title,
                          style: AppTextTheme().bodyText.copyWith(
                            color: textColor ?? Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      title,
                      style: AppTextTheme().bodyText.copyWith(
                        color: textColor ?? Colors.white,
                      ),
                    ),
            ),
    );
  }
}
