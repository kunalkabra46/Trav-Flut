import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final ButtonStyle? style;

  const LoadingButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: SpinKitThreeBounce(
                color: Theme.of(context).colorScheme.onPrimary,
                size: 16,
              ),
            )
          : child,
    );
  }
}