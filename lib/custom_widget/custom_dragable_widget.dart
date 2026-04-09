part of 'custom_widget.dart';

/// Provides the [DraggableScrollableSheet] inner [ScrollController] to nested
/// scroll views so overscroll at list edges can scroll the sheet content.
class DraggableSheetScrollScope extends InheritedWidget {
  const DraggableSheetScrollScope({
    super.key,
    required this.scrollController,
    required super.child,
  });

  final ScrollController scrollController;

  static ScrollController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DraggableSheetScrollScope>()
        ?.scrollController;
  }

  @override
  bool updateShouldNotify(DraggableSheetScrollScope oldWidget) {
    return scrollController != oldWidget.scrollController;
  }
}

/// Forwards vertical overscroll from a nested [ScrollView] to the parent sheet
/// [ListView] from [CustomDragableWidget] (same [ScrollController] as the sheet).
class SheetScrollBridge extends StatelessWidget {
  const SheetScrollBridge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth != 0) {
          return false;
        }
        final ScrollController? parent = DraggableSheetScrollScope.maybeOf(
          context,
        );
        if (parent == null || !parent.hasClients) {
          return false;
        }

        if (notification is OverscrollNotification) {
          final ScrollPosition pos = parent.position;
          final double next = (pos.pixels + notification.overscroll).clamp(
            pos.minScrollExtent,
            pos.maxScrollExtent,
          );
          if (next != pos.pixels) {
            parent.jumpTo(next);
          }
          return true;
        }

        if (notification is ScrollUpdateNotification) {
          final ScrollMetrics metrics = notification.metrics;
          final double? delta = notification.scrollDelta;
          if (delta == null || delta == 0) {
            return false;
          }
          const double eps = 0.5;
          final bool atTop =
              metrics.pixels <= metrics.minScrollExtent + eps;
          final bool atBottom =
              metrics.pixels >= metrics.maxScrollExtent - eps;

          if ((atTop && delta < 0) || (atBottom && delta > 0)) {
            final ScrollPosition pos = parent.position;
            final double next = (pos.pixels + delta).clamp(
              pos.minScrollExtent,
              pos.maxScrollExtent,
            );
            if (next != pos.pixels) {
              parent.jumpTo(next);
            }
            return true;
          }
        }
        return false;
      },
      child: child,
    );
  }
}

class CustomDragableWidget extends StatelessWidget {
  final List<Widget> childrens;
  final Widget? bottomWidget;
  final double? initialSize, miniSize;
  final double? maxSize;
  final List<double>? snapSizes;
  final DraggableScrollableController? scrollController;
  const CustomDragableWidget({
    super.key,
    required this.childrens,
    this.bottomWidget,
    this.initialSize,
    this.miniSize,
    this.maxSize,
    this.snapSizes,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialSize ?? 0.26,
      minChildSize: miniSize ?? 0.24,
      controller: scrollController,
      snap: true,
      snapSizes: snapSizes ?? [0.26, 0.55, 0.95],
      maxChildSize: maxSize ?? 0.95,
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
            child: SafeArea(
              top: false,
              child: Column(
                spacing: 5,
                children: [
                  // Handle (fixed)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: DraggableSheetScrollScope(
                      scrollController: scrollController,
                      child: ListView(
                        controller: scrollController,
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.horizontalPadding,
                        ),
                        children: childrens,
                      ),
                    ),
                  ),
                  ?bottomWidget,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
