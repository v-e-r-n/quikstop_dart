import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A native, responsive, and theme-friendly OTP Pin Field.
///
/// Handles SMS autofill, paste, keyboard focus, and backspace natively
/// without third-party dependencies or RenderFlex overflow bugs.
class QuikstopPinField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final Color primaryColor;
  final Color textColor;
  final Color inactiveBorderColor;
  final Color? boxColor;
  final double fieldHeight;
  final double fieldWidth;
  final double spacing;
  final bool autoFocus;

  const QuikstopPinField({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.primaryColor = const Color(0xFF10B981),
    this.textColor = Colors.white,
    this.inactiveBorderColor = Colors.grey,
    this.boxColor,
    this.fieldHeight = 48.0,
    this.fieldWidth = 40.0,
    this.spacing = 8.0,
    this.autoFocus = true,
  });

  @override
  State<QuikstopPinField> createState() => QuikstopPinFieldState();
}

class QuikstopPinFieldState extends State<QuikstopPinField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _controller.addListener(() {
      final text = _controller.text;
      widget.onChanged?.call(text);
      if (text.length == widget.length) {
        widget.onCompleted?.call(text);
      }
    });

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Clears the current PIN input and requests keyboard focus.
  void clear() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Offstage / Invisible real input field for native OS keyboard, paste, and autofill
          Opacity(
            opacity: 0.0,
            child: SizedBox(
              height: widget.fieldHeight,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                showCursor: false,
                enableSuggestions: false,
                autocorrect: false,
              ),
            ),
          ),
          // 2. Visible visual pin boxes driven by controller state
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final text = value.text;
              final focused = _focusNode.hasFocus;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxAvailable = constraints.maxWidth;
                  final totalSpacing = (widget.length - 1) * widget.spacing;
                  final idealWidth = (maxAvailable - totalSpacing) / widget.length;
                  final effectiveWidth = idealWidth.clamp(28.0, widget.fieldWidth);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.length, (index) {
                      final isCurrent = index == text.length && focused;
                      final isFilled = index < text.length;
                      final digit = isFilled ? text[index] : '';

                      final borderColor = isCurrent
                          ? widget.primaryColor
                          : isFilled
                              ? widget.primaryColor.withValues(alpha: 0.7)
                              : widget.inactiveBorderColor.withValues(alpha: 0.4);

                      return Container(
                        width: effectiveWidth,
                        height: widget.fieldHeight,
                        margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                        decoration: BoxDecoration(
                          color: widget.boxColor ?? Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: borderColor,
                            width: isCurrent ? 2.0 : 1.2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          digit,
                          style: TextStyle(
                            fontSize: effectiveWidth < 32 ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                        ),
                      );
                    }),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
