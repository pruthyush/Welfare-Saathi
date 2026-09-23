import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';

/// Modal dialog for Phone Number & OTP Authentication.
///
/// Tailored for rural plantation workers and fisherfolk in Kerala.
/// Strictly emphasizes that this account is for local profile saving and
/// safety alerts, and does NOT constitute an official government registration.
class AuthDialog extends StatefulWidget {
  final AuthService authService;
  final LocalizationService loc;
  final VoidCallback onAuthenticated;

  const AuthDialog({
    super.key,
    required this.authService,
    required this.loc,
    required this.onAuthenticated,
  });

  static Future<void> show({
    required BuildContext context,
    required AuthService authService,
    required LocalizationService loc,
    required VoidCallback onAuthenticated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AuthDialog(
        authService: authService,
        loc: loc,
        onAuthenticated: onAuthenticated,
      ),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = _phoneController.text.trim();
      await widget.authService.sendOtp(phoneNumber: raw);
      if (mounted) {
        setState(() {
          _isOtpSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = widget.loc.isMalayalam
            ? 'ദയവായി 6 അക്ക ഒ.ടി.പി നൽകുക'
            : 'Please enter a 6-digit OTP code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.verifyOtp(otpCode: otp);
      if (mounted) {
        Navigator.pop(context);
        widget.onAuthenticated();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMl = widget.loc.isMalayalam;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006D77).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: Color(0xFF006D77),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOtpSent
                                ? (isMl ? 'ഒ.ടി.പി നൽകുക' : 'Verify Mobile OTP')
                                : (isMl
                                    ? 'മൊബൈൽ നമ്പർ ഉപയോഗിച്ച് പ്രവേശിക്കുക'
                                    : 'Sign In with Mobile Number'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isOtpSent
                                ? (isMl
                                    ? 'നിങ്ങളുടെ ഫോണിലേക്ക് അയച്ച കോഡ് നൽകുക'
                                    : 'Enter the 6-digit verification code')
                                : (isMl
                                    ? 'വിവരങ്ങൾ സുരക്ഷിതമായി സൂക്ഷിക്കാൻ'
                                    : 'Save & retrieve household answers'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mandatory Non-Government Verification Notice
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF261D12) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isMl
                              ? 'ശ്രദ്ധിക്കുക: ഇത് ഉപയോക്താവിന്റെ വിവരങ്ങൾ സൂക്ഷിക്കുന്നതിനുള്ള അക്കൗണ്ട് മാത്രമാണ്. ഇത് സർക്കാരിന്റെ ഔദ്യോഗിക തിരിച്ചറിയലോ അനുമതിയോ അല്ല.'
                              : 'Notice: This account is exclusively for saving household screening details. It is NOT an official government identity or entitlement approval.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFFFD166) : const Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Error Message Banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // STEP 1: ENTER PHONE NUMBER
                if (!_isOtpSent) ...[
                  Text(
                    isMl ? 'മൊബൈൽ നമ്പർ (10 അക്കം)' : 'Mobile Number (10 digits)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
                          ),
                        ),
                        child: const Text(
                          '🇮🇳 +91',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            hintText: '98765 43210',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isMl ? 'മൊബൈൽ നമ്പർ നൽകുക' : 'Enter mobile number';
                            }
                            if (val.trim().length != 10) {
                              return isMl ? '10 അക്ക നമ്പർ നൽകുക' : 'Enter 10 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D77),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isMl ? 'ഒ.ടി.പി അയക്കുക (Send OTP)' : 'Send OTP',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],

                // STEP 2: ENTER OTP
                if (_isOtpSent) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '+91 ${_phoneController.text.trim()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isOtpSent = false;
                              _otpController.clear();
                              _errorMessage = null;
                            });
                          },
                          child: Text(
                            isMl ? 'മാറ്റുക' : 'Change',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Hackathon demo test hint
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D77).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF006D77)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMl
                                ? 'ഡെമോ പരിശോധനയ്ക്ക് ഒ.ടി.പി ആയി 123456 ഉപയോഗിക്കാം.'
                                : 'Demo Tip: Use code 123456 or SMS OTP for evaluation.',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF006D77)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    isMl ? '6 അക്ക ഒ.ടി.പി നൽകുക' : 'Enter 6-Digit OTP',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      hintText: '••••••',
                      hintStyle: const TextStyle(letterSpacing: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D77),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isMl ? 'സ്ഥിരീകരിക്കുക (Verify & Sign In)' : 'Verify & Sign In',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : _sendOtp,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        isMl ? 'ഒ.ടി.പി വീണ്ടും അയക്കുക (Resend Code)' : 'Resend Code',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
