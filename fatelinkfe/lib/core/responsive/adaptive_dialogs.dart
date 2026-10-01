import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'responsive_context.dart';

class AdaptiveDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final double maxWidth;
  final ShapeBorder? shape;
  final Color? backgroundColor;

  const AdaptiveDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.maxWidth = 420.0,
    this.shape,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor ?? Colors.white,
      shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: math.min(context.screenHeight * 0.85, 600.0),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  child: title!,
                ),
                const SizedBox(height: 12),
              ],
              if (content != null) ...[
                DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                  child: content!,
                ),
                const SizedBox(height: 24),
              ],
              if (actions != null && actions!.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdaptiveBottomSheetContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;

  const AdaptiveBottomSheetContainer({
    super.key,
    required this.child,
    this.maxWidth = 520.0,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = context.keyboardHeight;
    final safeBottom = context.safeBottom;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: math.min(context.screenHeight * 0.90, 700.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: borderRadius ?? const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: bottomInset > 0 ? bottomInset + 8.0 : safeBottom + 16.0,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
