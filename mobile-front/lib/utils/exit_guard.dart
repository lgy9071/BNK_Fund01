import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'exit_popup.dart'; // 방금 bool 리턴으로 바꾼 showExitPopup

class ExitGuard extends StatefulWidget {
  final Widget child;
  final bool enabled; // 화면별로 끄고 켤 수 있게

  const ExitGuard({super.key, required this.child, this.enabled = true});

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  bool _exiting = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_exiting) return;
        _exiting = true;
        try {
          final shouldExit = await showExitPopup(context);
          if (shouldExit) {
            await SystemNavigator.pop();
          }
        } finally {
          _exiting = false;
        }
      },
      child: widget.child,
    );
  }
}