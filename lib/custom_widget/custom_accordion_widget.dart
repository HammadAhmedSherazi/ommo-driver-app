import 'package:flutter/material.dart';
import 'package:ommo/utils/utils.dart';

class CustomAccordionWidget extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const CustomAccordionWidget({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  CustomAccordionWidgetState createState() => CustomAccordionWidgetState();
}

class CustomAccordionWidgetState extends State<CustomAccordionWidget>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    if (_expanded) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _expanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: _toggle,
          child: Row(
            spacing: 8,
            children: [
             RotationTransition(
  turns: Tween(begin: 0.0, end: 0.5).animate(_controller), 
  child: const Icon(Icons.arrow_drop_down, size: 30, color: Colors.black),
),
             
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTextTheme().lightText.copyWith(
                    fontSize: 16
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: Container(),
          secondChild: widget.child,
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
