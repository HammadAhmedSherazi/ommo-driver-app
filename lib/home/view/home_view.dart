import 'package:flutter/material.dart';
import './home_mobile_view.dart';
import '../../custom_widget/custom_widget.dart';
import 'home_tablet_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeMobileView();
    //  ResponsiveLayout(
    //   mobileTemplate: HomeMobileView(),
    //   tabletTemplate: HomeTabletView(),
    // );
  }
}


