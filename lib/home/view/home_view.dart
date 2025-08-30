import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/home/view/map_view.dart';

import 'package:ommo/utils/utils.dart';

import '../home.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileTemplate: HomeMobileView(),
      tabletTemplate: HomeTabletView(),
    );
  }
}

class HomeTabletView extends StatelessWidget {
  const HomeTabletView({super.key});

  @override
  Widget build(BuildContext context) {
    return context.isLandscape
        ? Scaffold(backgroundColor: Color(0xffF4F6F8))
        : Scaffold(body: Center(child: Text("Portrait")));
  }
}

class HomeMobileView extends StatefulWidget {
  const HomeMobileView({super.key});

  @override
  State<HomeMobileView> createState() => _HomeMobileViewState();
}

class _HomeMobileViewState extends State<HomeMobileView> {
  final List<String> stationList = [
    "Truck stops",
    "Weight stations",
    "Parking",
    "Rest areas",
    "Truck washes",
    "Dealership",
  ];
  final List<PlaceDataModel> places = [
    PlaceDataModel(title: "Walmart", icon: AppIcons.walmartIcon, address: "210 Riverside Drive, New York, NY 10025", time: "10 pm", shopStatus: "Open", distance: 63, rating: 5.0, reviewCount: 12, storeType: "Store"),
    PlaceDataModel(title: "Loves travel stop", icon: AppIcons.loveStoreIcon, address: "210 Riverside Drive, New York, NY 10025", time: "10 pm", shopStatus: "Open", distance: 63, rating: 5.0, reviewCount: 12, storeType: "Truck stop"),
    PlaceDataModel(title: "CityPark", icon: AppIcons.walmartIcon, address: "210 Riverside Drive, New York, NY 10025", time: "12 pm", shopStatus: "Close", distance: 63, rating: 5.0, reviewCount: 12, storeType: "Parking"),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(76),

        child: AppBar(
          leadingWidth: context.screenWidth * 0.45,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              20.w,
             Image.asset(AppIcons.logo, width: 126,height: 22,)
               ],
          ),
          actions: [
            Container(
              height: 44,
              width: 44,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Color(0xFFEBEEF2),
                  width: 1,
                ), // rgba(235, 238, 242, 1)
                borderRadius: BorderRadius.circular(8), // Optional
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.04), // rgba(0, 0, 0, 0.04)
                    blurRadius: 6, // Spread of the blur
                    offset: Offset(0, 2), // X=0, Y=2
                  ),
                ],
              ),
              child: SvgPicture.asset(AppIcons.menuIcon, width: 20, height: 20,),
            ),
            20.w,
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(0.8),
            child: Divider(),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background content
         MapView(),
          Container(
            margin: EdgeInsets.only(top: 10),
            height: 40,
            // width: double.infinity,
            child: ListView.separated(
              itemCount: stationList.length,
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.horizontalPadding,
              ),
              separatorBuilder: (context, index) => 5.w,
              itemBuilder: (context, index) => Container(
                // width: 100,
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color.fromRGBO(
                      235,
                      238,
                      242,
                      1,
                    ), // border color
                    width: 1, // border width
                  ),
                  borderRadius: BorderRadius.circular(
                    50,
                  ), // optional rounded corners
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.04), // shadow color
                      offset: Offset(0, 2), // x=0, y=2 (downwards)
                      blurRadius: 6, // soft shadow
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: index % 2 == 0
                          ? Color(0xff4676F6)
                          : Color(0xffFFC300),
                      child: Text(
                        stationList[index].splitMapJoin('')[0],
                        style: AppTextTheme().headingText.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(stationList[index], style: AppTextTheme().bodyText),
                  ],
                ),
              ),
              scrollDirection: Axis.horizontal,
            ),
            // width: double.infinity,
          ),
          // Draggable Bottom Sheet (always visible)
          DraggableScrollableSheet(
            initialChildSize: 0.26,
            minChildSize: 0.24,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(
                      context,
                    ).viewInsets.bottom, // 👈 safe for keyboard
                  ),
                  child: Column(
                    spacing: 10,
                    children: [
                      // Handle (fixed)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        height: 5,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // Search bar (fixed)

                      // Scrollable content
                      Expanded(
                        child: ListView(
                          // physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.horizontalPadding,
                          ),
                          controller: scrollController,
                          shrinkWrap: true,
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: "Find a destination...",
                                filled: true,
                                fillColor: const Color.fromRGBO(
                                  244,
                                  246,
                                  248,
                                  1,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            15.h,
                            CustomButtonWidget(
                              title: "Get Direction",
                              onPressed: () {},
                              icon: Icon(Icons.directions, color: Colors.white),
                            ),
                            15.h,
                            DashedLine(color: Color(0xffEBEEF2)),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(radius: 25, backgroundColor: AppColorTheme().primary.withValues(alpha: 0.2), child: SvgPicture.asset(AppIcons.navigationIconGreen),),
                              title: Text(
                                "210 Riverside Drive",
                                style: AppTextTheme().bodyText.copyWith(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                "New York, NY 10025",
                                style: AppTextTheme().lightText.copyWith(
                                  color: Color(0xff888BA1),
                                ),
                              ),
                            ),
                            15.h,
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                radius: 25, child: SvgPicture.asset(AppIcons.weatherIcon),),
                              title: Text(
                                "24°C",
                                style: AppTextTheme().bodyText.copyWith(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Row(
                                spacing: 4,
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    size: 16,
                                    color: Color(0xffFF4F5B),
                                  ),
                                  Text(
                                    "The light rain next 2 hours",
                                    style: AppTextTheme().lightText.copyWith(
                                      color: Color(0xff888BA1),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, color: Colors.black, size: 15, weight: 30,),
                            ),
                            15.h,
                            DashedLine(color: Color(0xffEBEEF2)),
                            15.h,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Text("Nearby places", style: AppTextTheme().headingText.copyWith(
                                    fontSize: 16
                                  ),),
                                  Text("More", style: AppTextTheme().bodyText.copyWith(
                                    color: AppColorTheme().primary
                                  ),)
                              ],
                            ),
                            15.h,
                            ...List.generate(places.length, (index) {
                              final place = places[index];
                              return Row(
                                spacing: 10,
                                crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 25,backgroundColor: Color(0xffF4F6F8), child: CircleAvatar(
                                  radius: 13,
                                  backgroundImage: AssetImage(place.icon),
                                  
                                ),),
                                Expanded(child: Column(
                                 
                                  spacing: 5,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(place.title, style: AppTextTheme().headingText.copyWith(
                                            fontSize: 16
                                          ),),
                                        ),
                                        Container(
                                          width: 28,
                                          height: 28,
                                          // padding: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Color(0xFFEBEEF2),
                  width: 1,
                ), // rgba(235, 238, 242, 1)
                borderRadius: BorderRadius.circular(8), // Optional
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.04), // rgba(0, 0, 0, 0.04)
                    blurRadius: 6, // Spread of the blur
                    offset: Offset(0, 2), // X=0, Y=2
                  ),
                ],
              ),
              child: Icon(Icons.bookmark_border, size: 17, color: Colors.black,),
                                        )
                                      ],
                                    ),
                                    Row(
                                      spacing: 3,
                                      children: [
                                        // Icon(Icons.star, color: Color(0xffFF8800), size: 15,),
                                        SvgPicture.asset(AppIcons.ratingIcon),
                                        Text(place.rating.toString(), style: AppTextTheme().bodyText.copyWith(
                                           color: Color(0xffFF8800)
                                        ),),
                                        Text("(${place.reviewCount})", style: AppTextTheme().bodyText.copyWith(
                                        
                                          color: Color(0xff888BA1)
                                        ),),
                                        Text("  • ${place.storeType} • ${place.distance} mi",style: AppTextTheme().bodyText.copyWith(
                                        
                                          color: Color(0xff888BA1)
                                        ))
                                      ],
                                    ),
                                    Text(place.address, style: AppTextTheme().bodyText,),
                                    Row(
                                      children: [
                                        Text(place.shopStatus == "Open" ? "Opened" : "Closed", style: AppTextTheme().bodyText.copyWith(
                                          color: place.shopStatus == "Open" ? AppColorTheme().primary : Colors.redAccent

                                        ),),
                                         Text("  • ${place.shopStatus == "Open" ? "Closes" : "Opens" } at ${place.time} ",style: AppTextTheme().bodyText.copyWith(
                                       
                                          color: Color(0xff888BA1)
                                        ))
                                      ],
                                    ),
                                    10.h
                                  ],
                                )
                                )
                              ],
                            );
                            }),
                             DashedLine(color: Color(0xffEBEEF2)), 
                             15.h,
                              Text("Quick Actions", style: AppTextTheme().headingText.copyWith(
                                    fontSize: 16
                                  ),),
                                15.h,
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 7,
                                    horizontal: 10
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                     border: Border.all(
                  color: Color(0xFFEBEEF2),
                  width: 1
                ), 
                                  ),
                                  child: Row(
                                    spacing: 5,
                                    children: [
                                      Icon(Icons.bookmark_sharp),
                                      Expanded(
                                        child: Text("Saved & recent places", style: AppTextTheme().bodyText.copyWith(
                                          fontSize: 16
                                        ),),
                                      ),
                                      Icon(Icons.arrow_forward_ios, color: Colors.black, size: 15, weight: 30,)
                                    ],
                                  ),
                                ),
                                20.h,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DashedLine extends StatelessWidget {
  final double height;
  final Color color;

  const DashedLine({super.key, this.height = 1, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(color: color, height: height),
      child: SizedBox(width: double.infinity, height: height),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final double height;
  final Color color;

  _DashedLinePainter({required this.color, required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = height;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
