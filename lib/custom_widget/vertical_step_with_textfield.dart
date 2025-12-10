part of 'custom_widget.dart';

class VerticalStepWithTextField extends StatefulWidget {
  final List<TextEditingController> textControllers;
  final List<FocusNode> focusNode;
  final VoidCallback removeFieldTap;
  final VoidCallback? onDestinationFieldTap;
  final bool readOnly;

  const VerticalStepWithTextField({
    super.key,
    this.readOnly = false,
    required this.textControllers,
    this.onDestinationFieldTap,
    required this.removeFieldTap,
    required this.focusNode,
  });

  @override
  State<VerticalStepWithTextField> createState() =>
      _VerticalStepWithTextFieldState();
}

class _VerticalStepWithTextFieldState extends State<VerticalStepWithTextField> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        /// Left side (steps)
        Column(
          children: List.generate(widget.textControllers.length, (index) {
            final isFirst = index == 0;
            final isLast = index == widget.textControllers.length - 1;

            return Column(
              children: [
                // Top icon
                if (isFirst) 20.h,
                if (isFirst)
                  Container(
                    height: 18,
                    width: 18,
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColorTheme().primary,
                      shape: BoxShape.circle,
                      border: Border.all(width: 1, color: Colors.white),
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 3.2),
                          blurRadius: 6.4,
                          spreadRadius: 0,
                          color: Color(0x7A000000),
                        ),
                        BoxShadow(
                          offset: Offset(0, 0),
                          blurRadius: 0,
                          spreadRadius: 2.4,
                          color: Color(0xffFFFFFF),
                        ),
                      ],
                    ),
                  )
                else if (isLast)
                  Container(
                    height: 20,
                    width: 20,
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Color(0xffFF4F5B),
                      shape: BoxShape.circle,
                      border: Border.all(width: 1, color: Colors.white),
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 3.2),
                          blurRadius: 6.4,
                          spreadRadius: 0,
                          color: Color(0x7A000000),
                        ),
                        BoxShadow(
                          offset: Offset(0, 0),
                          blurRadius: 0,
                          spreadRadius: 2.4,
                          color: Color(0xffFFFFFF),
                        ),
                      ],
                    ),
                    child: Image.asset(AppImages.destinationPointPin),
                  )
                else
                  Image.asset(AppImages.stopPointIcon, height: 20, width: 20),
                // Draw dotted line only between items
                if (!isLast)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.6),
                    child: SizedBox(
                      height: 35, // match with textfield height + spacing
                      child: CustomPaint(painter: DottedLinePainter()),
                    ),
                  ),
              ],
            );
          }),
        ),

        /// Right side (textfields)
        Expanded(
          child: Column(
            spacing: 10,
            children: List.generate(widget.textControllers.length, (index) {
              return CustomTextfieldWidget(
                focusNode: widget.focusNode[index],
                controller: widget.textControllers[index],
                onTap: index == 1 ? widget.onDestinationFieldTap : null,
                readOnly: index == 0 ? true : widget.readOnly,
                hintText: "Enter a location",
              );
            }),
          ),
        ),
      ],
    );
  }
}

// Dotted vertical line painter
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 2, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = AppColorTheme().primary
      ..strokeWidth = 1;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
