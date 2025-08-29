part of './custom_widget.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileTemplate;
  final Widget tabletTemplate;

  const ResponsiveLayout({
    super.key,
    required this.mobileTemplate,
    required this.tabletTemplate,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      return mobileTemplate;
    } else {
      return tabletTemplate;
    }
  }
}
