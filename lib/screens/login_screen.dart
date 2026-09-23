import 'package:flutter/material.dart';
import '../controllers/screening_controller.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

/// Full-page Authentication Screen enforcing single-time login before
/// accessing household welfare screening or persistent profile storage.
class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final LocalizationService loc;
  final ScreeningController controller;
  final VoidCallback onAuthenticated;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.loc,
    required this.controller,
    required this.onAuthenticated,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() {
        _errorMessage = widget.loc.isMalayalam
            ? 'ദയവായി 10 അക്ക മൊബൈൽ നമ്പർ നൽകുക.'
            : 'Please enter your 10-digit mobile number.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.sendOtp(phoneNumber: rawPhone);
      if (mounted) {
        setState(() {
          _otpSent = true;
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

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = widget.loc.isMalayalam
            ? 'ദയവായി 6 അക്ക ഒ.ടി.പി നൽകുക.'
            : 'Please enter the 6-digit OTP code.';
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
        setState(() {
          _isLoading = false;
        });
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
    final loc = widget.loc;
    final isMl = loc.isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.tr('appTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: loc.tr('highContrast'),
            icon: Icon(widget.controller.highContrast ? Icons.contrast : Icons.contrast_outlined),
            onPressed: () => widget.controller.toggleHighContrast(),
          ),
          IconButton(
            tooltip: loc.tr('fontSize'),
            icon: Icon(widget.controller.largeText ? Icons.text_fields : Icons.format_size),
            onPressed: () => widget.controller.toggleLargeText(),
          ),
          const SizedBox(width: 8),
          LanguageSelector(loc: loc),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)]
                          : [const Color(0xFF006D77), const Color(0xFF0F4C5C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volunteer_activism_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        loc.tr('appTitle'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMl
                            ? 'തോട്ടം & മത്സ്യത്തൊഴിലാളി ക്ഷേമസഹായി'
                            : 'Plantation & Fisherfolk Welfare Assistant',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFFD166) : const Color(0xFFFFDDD2),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isMl
                            ? 'നിങ്ങളുടെ കുടുംബ വിവരങ്ങൾ സുരക്ഷിതമായി സൂക്ഷിക്കാനും കൃത്യമായ ക്ഷേമപദ്ധതികൾ അറിയാനും ലോഗിൻ ചെയ്യുക.'
                            : 'Sign in once to securely store your household profile and access 16 verified welfare schemes.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Main Login Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF006D77).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.phone_android_rounded, color: Color(0xFF006D77), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMl ? 'മൊബൈൽ ലോഗിൻ' : 'Mobile Sign In',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _otpSent
                                        ? (isMl ? 'ഒ.ടി.പി നൽകുക' : 'Enter 6-digit OTP code')
                                        : (isMl ? 'മൊബൈൽ നമ്പർ നൽകുക' : 'Enter 10-digit mobile number'),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Error Banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Step 1: Phone input
                        if (!_otpSent) ...[
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: isMl ? 'മൊബൈൽ നമ്പർ (10 അക്കം)' : 'Mobile Number',
                              hintText: '9847123456',
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                margin: const EdgeInsets.only(right: 8),
                                alignment: Alignment.center,
                                width: 68,
                                child: const Text(
                                  '+91',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              border: const OutlineInputBorder(),
                              counterText: '',
                            ),
                            onSubmitted: (_) => _handleSendOtp(),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleSendOtp,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.sms_rounded),
                            label: Text(
                              _isLoading
                                  ? (isMl ? 'അയയ്ക്കുന്നു...' : 'Sending...')
                                  : (isMl ? 'ഒ.ടി.പി അയക്കുക (Send OTP)' : 'Send OTP Code'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006D77),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ] else ...[
                          // Step 2: OTP input
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF262626) : const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Color(0xFF006D77), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${isMl ? "കോഡ് അയച്ചത്:" : "Code sent to:"} ${_phoneController.text.trim()}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _otpSent = false;
                                            _otpController.clear();
                                            _errorMessage = null;
                                          });
                                        },
                                  child: Text(isMl ? 'മാറ്റുക' : 'Change'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            enabled: !_isLoading,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: isMl ? '6 അക്ക ഒ.ടി.പി നൽകുക' : 'Enter 6-digit OTP',
                              hintText: '123456',
                              border: const OutlineInputBorder(),
                              counterText: '',
                            ),
                            onSubmitted: (_) => _handleVerifyOtp(),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleVerifyOtp,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(
                              _isLoading
                                  ? (isMl ? 'പരിശോധിക്കുന്നു...' : 'Verifying...')
                                  : (isMl ? 'സ്ഥിരീകരിച്ച് തുടരുക' : 'Verify & Continue'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006D77),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Hackathon Demo Evaluation Tip
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF261D12) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFD97706), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isMl
                                      ? 'ഡെമോ നിർദ്ദേശം: നിങ്ങളുടെ 10 അക്ക മൊബൈൽ നമ്പർ നൽകുക. പരിശോധനയ്ക്കായി 123456 എന്ന കോഡ് ഉപയോഗിക്കാവുന്നതാണ്.'
                                      : 'Hackathon Evaluation Tip: Enter any 10-digit mobile number, then use SMS code or demo evaluation code 123456.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Non-government Disclaimer
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMl
                            ? 'ശ്രദ്ധിക്കുക: ഈ ലോഗിൻ നിങ്ങളുടെ കുടുംബ വിവരങ്ങൾ ഈ ഉപകരണത്തിൽ മാത്രമായി സുരക്ഷിതമായി സൂക്ഷിക്കാനുള്ളതാണ്. ഇതൊരു ഔദ്യോഗിക സർക്കാർ തിരിച്ചറിയൽ രേഖയോ ആനുകൂല്യ അനുമതിയോ അല്ല.'
                            : 'Notice: This account is exclusively for saving household screening details locally and in your session. It does NOT constitute an official government identity or benefit approval.',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
