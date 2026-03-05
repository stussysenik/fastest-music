import 'package:flutter/material.dart';

class ComposableContainer extends StatelessWidget {
  final Widget child;
  final double widthFactor;
  final EdgeInsetsGeometry padding;

  const ComposableContainer({
    super.key,
    required this.child,
    this.widthFactor = 1.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return child;
          },
        ),
      ),
    );
  }
}
