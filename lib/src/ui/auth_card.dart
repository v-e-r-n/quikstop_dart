import 'package:flutter/material.dart';
import '../auth/models.dart';
import '../otp/client.dart';
import 'pin_field.dart';

/// Recipient type for the passwordless authentication card.
enum QuikstopRecipientType {
  email,
  phone,
  custom,
}

/// A complete, styled, responsive Card widget for Passwordless OTP sign-in.
/// Supports emails, phone numbers, and custom identifiers.
/// Uses native [QuikstopPinField] for entering verification codes without overflow bugs.
class QuikstopAuthCard extends StatefulWidget {
  final QuikstopOTPClient client;
  final ValueChanged<AuthTokens> onSuccess;
  final String? appTitle;
  final Widget? logo;
  final QuikstopRecipientType recipientType;
  final String? inputLabel;
  final String? inputHint;
  final IconData? inputIcon;
  final TextInputType? keyboardType;
  final String requestButtonText;
  final String verifyButtonText;
  final Color primaryColor;
  final Color cardColor;
  final Color textColor;
  final int codeLength;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final String Function(String input)? inputValidator;

  const QuikstopAuthCard({
    super.key,
    required this.client,
    required this.onSuccess,
    this.appTitle,
    this.logo,
    this.recipientType = QuikstopRecipientType.email,
    this.inputLabel,
    this.inputHint,
    this.inputIcon,
    this.keyboardType,
    this.requestButtonText = 'Send Verification Code',
    this.verifyButtonText = 'Verify & Sign In',
    this.primaryColor = const Color(0xFF10B981),
    this.cardColor = const Color(0xFF1E293B),
    this.textColor = Colors.white,
    this.codeLength = 6,
    this.constraints,
    this.padding,
    this.inputValidator,
  });

  @override
  State<QuikstopAuthCard> createState() => _QuikstopAuthCardState();
}

class _QuikstopAuthCardState extends State<QuikstopAuthCard> {
  final _recipientController = TextEditingController();
  final _pinFieldKey = GlobalKey<QuikstopPinFieldState>();

  bool _showOTPField = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _otpCode = '';

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  String get _resolvedLabel {
    if (widget.inputLabel != null) return widget.inputLabel!;
    switch (widget.recipientType) {
      case QuikstopRecipientType.phone:
        return 'Phone Number';
      case QuikstopRecipientType.custom:
        return 'Recipient Identifier';
      case QuikstopRecipientType.email:
        return 'Email Address';
    }
  }

  IconData get _resolvedIcon {
    if (widget.inputIcon != null) return widget.inputIcon!;
    switch (widget.recipientType) {
      case QuikstopRecipientType.phone:
        return Icons.phone_outlined;
      case QuikstopRecipientType.custom:
        return Icons.person_outline;
      case QuikstopRecipientType.email:
        return Icons.email_outlined;
    }
  }

  TextInputType get _resolvedKeyboardType {
    if (widget.keyboardType != null) return widget.keyboardType!;
    switch (widget.recipientType) {
      case QuikstopRecipientType.phone:
        return TextInputType.phone;
      case QuikstopRecipientType.custom:
        return TextInputType.text;
      case QuikstopRecipientType.email:
        return TextInputType.emailAddress;
    }
  }

  Future<void> _submitRecipient() async {
    final recipient = _recipientController.text.trim();
    if (recipient.isEmpty) return;

    if (widget.inputValidator != null) {
      final validationErr = widget.inputValidator!(recipient);
      if (validationErr.isNotEmpty) {
        setState(() => _errorMessage = validationErr);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.client.knock(recipient);
      if (!mounted) return;
      setState(() {
        _showOTPField = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is QuikstopException ? e.message : e.toString();
      });
    }
  }

  Future<void> _submitOTP() async {
    final recipient = _recipientController.text.trim();
    final otp = _otpCode.trim();
    if (recipient.isEmpty || otp.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tokens = await widget.client.verify(recipient, otp);
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onSuccess(tokens);
    } catch (e) {
      if (!mounted) return;
      _pinFieldKey.currentState?.clear();
      setState(() {
        _isLoading = false;
        _errorMessage = e is QuikstopException ? e.message : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveConstraints = widget.constraints ?? const BoxConstraints(maxWidth: 440);

    return LayoutBuilder(
      builder: (context, parentConstraints) {
        final isNarrow = parentConstraints.maxWidth < 400;
        final innerPadding = widget.padding ??
            EdgeInsets.symmetric(
              horizontal: isNarrow ? 20.0 : 32.0,
              vertical: isNarrow ? 24.0 : 32.0,
            );

        return Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: effectiveConstraints,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Card(
                color: widget.cardColor,
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: innerPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.logo != null)
                        Center(
                          child: Semantics(
                            label: widget.appTitle ?? 'Application Logo',
                            image: true,
                            child: widget.appTitle != null
                                ? Tooltip(
                                    message: widget.appTitle!,
                                    child: widget.logo!,
                                  )
                                : widget.logo!,
                          ),
                        )
                      else if (widget.appTitle != null)
                        Center(
                          child: Text(
                            widget.appTitle!,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: widget.primaryColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                      if (!_showOTPField) ...[
                        TextField(
                          controller: _recipientController,
                          keyboardType: _resolvedKeyboardType,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitRecipient(),
                          style: TextStyle(color: widget.textColor),
                          decoration: InputDecoration(
                            labelText: _resolvedLabel,
                            hintText: widget.inputHint,
                            hintStyle: TextStyle(color: widget.textColor.withValues(alpha: 0.4)),
                            labelStyle: TextStyle(color: widget.textColor.withValues(alpha: 0.7)),
                            prefixIcon: Icon(_resolvedIcon, color: widget.primaryColor),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: widget.textColor.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: widget.primaryColor, width: 2),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Code sent to: ${_recipientController.text}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: widget.textColor.withValues(alpha: 0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _showOTPField = false;
                                        _otpCode = '';
                                        _errorMessage = null;
                                      });
                                    },
                              child: Text('Change', style: TextStyle(color: widget.primaryColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        QuikstopPinField(
                          key: _pinFieldKey,
                          length: widget.codeLength,
                          primaryColor: widget.primaryColor,
                          textColor: widget.textColor,
                          onCompleted: (String code) {
                            _otpCode = code;
                            _submitOTP();
                          },
                          onChanged: (text) {
                            _otpCode = text;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_isLoading)
                        Center(child: CircularProgressIndicator(color: widget.primaryColor))
                      else
                        ElevatedButton(
                          onPressed: _showOTPField ? _submitOTP : _submitRecipient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          ),
                          child: Text(
                            _showOTPField ? widget.verifyButtonText : widget.requestButtonText,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
