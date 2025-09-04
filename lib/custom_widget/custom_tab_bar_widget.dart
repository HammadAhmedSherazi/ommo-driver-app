part of 'custom_widget.dart';

class CustomTabBarWidget extends StatefulWidget {
  final List<String> options;
  final TabController tabController;
  const CustomTabBarWidget({super.key, required this.options, required this.tabController});

  @override
  State<CustomTabBarWidget> createState() => _CustomTabBarWidgetState();
}

class _CustomTabBarWidgetState extends State<CustomTabBarWidget>
    with SingleTickerProviderStateMixin {
  // late TabController _tabController;
  // late final List<String> locationOpt ;

 
  // @override
  // void dispose() {
  //   widget.tabController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
          height: 40,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: const Color(0xffF5F7F9),
          ),
          child: TabBar(
            controller: widget.tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColorTheme().primary, // active color
            unselectedLabelColor:  AppColorTheme().secondary, // inactive color
            tabs: widget.options.map((label) {
              return Tab(
                child: Text(
                  label,
                  style: AppTextTheme().bodyText,
                ),
              );
            }).toList(),
          ),
        )
     ;
  }
}
