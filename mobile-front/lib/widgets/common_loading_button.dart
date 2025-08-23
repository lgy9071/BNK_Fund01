import 'package:flutter/material.dart';


class CommonLoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double fontSize;
  final Color backgroundColor;
  final Color textColor;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isLoading;
  final Color? disabledBackgroundColor;
  final double? loadingIndicatorSize;
  final double? loadingStrokeWidth;

  const CommonLoadingButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontSize = 16,
    this.backgroundColor = const Color(0xFF0064FF),
    this.textColor = Colors.white,
    this.fontWeight = FontWeight.w600,
    this.margin = const EdgeInsets.all(0),
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.borderRadius = 12,
    this.isLoading = false,
    this.disabledBackgroundColor,
    this.loadingIndicatorSize = 20,
    this.loadingStrokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          disabledBackgroundColor: disabledBackgroundColor ?? Colors.grey.shade300,
        ),
        child: isLoading
            ? SizedBox(
          height: loadingIndicatorSize,
          width: loadingIndicatorSize,
          child: CircularProgressIndicator(
            color: textColor,
            strokeWidth: loadingStrokeWidth!,
          ),
        )
            : Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}