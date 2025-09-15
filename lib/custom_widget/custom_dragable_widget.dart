part of 'custom_widget.dart';
class CustomDragableWidget extends StatelessWidget {
  final List<Widget> childrens;
  final Widget? bottomWidget;
  final double? initialSize, miniSize;
  const CustomDragableWidget({super.key, required this.childrens, this.bottomWidget, this.initialSize, this.miniSize});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
              initialChildSize: initialSize ?? 0.26,
              minChildSize:miniSize ?? 0.24,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 2),
                    ],
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
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            shrinkWrap: true,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.horizontalPadding,
                            ),
                            children: childrens),
                        ),
                        ?bottomWidget
                      ],
                    ),
                  ),
                );
              },
            )
        ;
  }
}