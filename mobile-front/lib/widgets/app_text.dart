// lib/widgets/app_text.dart
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 1) 무조건 한 줄 유지, 넘치면 자동 축소
class AppOneLineText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign align;
  final double minFontSize; // 너무 작아지지 않도록 하한
  const AppOneLineText(
      this.text, {
        super.key,
        this.style,
        this.align = TextAlign.center,
        this.minFontSize = 10, // 필요 시 조절
      });

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      maxLines: 1,
      minFontSize: minFontSize,
      stepGranularity: 0.5,
      textAlign: align,
      overflow: TextOverflow.ellipsis,
      style: style ?? TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
    );
  }
}

/// 2) N줄까지 허용, 박스 안에 맞게 자동 축소
class AppAdaptiveText extends StatelessWidget {
  final String text;
  final int maxLines;     // 허용 줄 수
  final double minFontSize;
  final TextStyle? style;
  final TextAlign align;
  const AppAdaptiveText(
      this.text, {
        super.key,
        this.maxLines = 2,
        this.minFontSize = 12,
        this.style,
        this.align = TextAlign.start,
      });

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      maxLines: maxLines,
      minFontSize: minFontSize,
      stepGranularity: 0.5,
      textAlign: align,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

/// 3) Row 내부에서 한 줄 + 말줄임 (자동 축소는 X, 레이아웃만 보호)
class AppRowEllipsisText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const AppRowEllipsisText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
