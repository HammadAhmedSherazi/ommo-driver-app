part of 'custom_widget.dart';



class VerticalStepWithTextField extends StatefulWidget {
  final List<TextEditingController> textControllers;
  final List<FocusNode> focusNode;
  final VoidCallback removeFieldTap;
  const VerticalStepWithTextField({super.key, required this.textControllers, required this.removeFieldTap, required this.focusNode});

  @override
  State<VerticalStepWithTextField> createState() => _VerticalStepWithTextFieldState();
}

class _VerticalStepWithTextFieldState extends State<VerticalStepWithTextField> {
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
            children: List.generate(widget.textControllers.length, (index) {
              return   CustomTextfieldWidget(
                focusNode: widget.focusNode[index],
                controller: widget.textControllers[index],
                // onTap: (){
                //   setState(() {
                    
                //   });
                // },
                hintText: "Enter a location",
                suffixIcon: widget.focusNode[index].hasFocus ? IconButton(onPressed: widget.removeFieldTap, icon: Icon(Icons.cancel), style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                  visualDensity: VisualDensity(
                    horizontal: -4.0,
                    vertical: -4.0
                  )
                ),) : null,
               
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
