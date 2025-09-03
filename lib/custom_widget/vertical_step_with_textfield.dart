part of 'custom_widget.dart';

class VerticalStepWithTextField extends StatelessWidget {
  final List<TextEditingController> textControllers;

  const VerticalStepWithTextField({super.key, required this.textControllers});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        /// Left side (steps)
        Column(
          
          children: List.generate(textControllers.length, (index) {
            final isFirst = index == 0;
            final isLast = index == textControllers.length - 1;

            return Column(
              children: [
                // Top icon
               if(isFirst) 20.h,
                if (isFirst)
                  const Icon(Icons.circle_outlined, size: 15)
                else if (isLast)
                  const Icon(Icons.location_on, size: 24, )
                else
                  const Icon(Icons.circle_outlined, size: 15),
            
                // Draw dotted line only between items
                if (!isLast)
                  Padding(
                    padding:EdgeInsets.symmetric(
                      vertical: 5.6
                    ),
                    child: SizedBox(
                      height: 40, // match with textfield height + spacing
                      child: CustomPaint(
                        painter: DottedLinePainter(),
                      ),
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
            children: List.generate(textControllers.length, (index) {
              return CustomTextfieldWidget(
                controller: textControllers[index],
                hintText: "sds",
               
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
