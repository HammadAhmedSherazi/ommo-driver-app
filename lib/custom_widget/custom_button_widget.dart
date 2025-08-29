part of 'custom_widget.dart';

class CustomButtonWidget extends StatelessWidget {
  final bool isLoad;
  final String title;
  final Widget? icon;
  final VoidCallback onPressed;
  const CustomButtonWidget({super.key, required this.title, this.isLoad = false, required this.onPressed, this.icon });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Platform.isIOS ? CupertinoButton(
        color: AppColorTheme().primary,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(30),
        onPressed: onPressed, child: icon != null ? Row(
          spacing: 5,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon!,
            Text(title, style: AppTextTheme().bodyText.copyWith(
          color: Colors.white
        ),)
          ],
        ) :  Text(title, style: AppTextTheme().bodyText.copyWith(
          color: Colors.white
        ),)) : ElevatedButton(
          style: ButtonStyle(
            elevation: WidgetStatePropertyAll(0.0),
            backgroundColor: WidgetStatePropertyAll(AppColorTheme().primary),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))
            
          ),
          onPressed: onPressed, child: icon != null?Row(
              spacing: 5,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon!,
            Text(title, style: AppTextTheme().bodyText.copyWith(
          color: Colors.white
        ),)
          ],
        ) : Text(title, style: AppTextTheme().bodyText.copyWith(
          color: Colors.white
        ),)),
    );
  }
}