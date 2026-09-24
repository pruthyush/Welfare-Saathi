import 'package:flutter/material.dart';
import '../controllers/screening_controller.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() {
        _errorMessage = widget.loc.isMalayalam ? 'ദയവായി 10 അക്ക മൊബൈൽ നമ്പർ നൽകുക.' : 'Please enter your 10-digit mobile number.';
      });
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await widget.authService.sendOtp(phoneNumber: rawPhone);
      if (mounted) {
        setState(() { _otpSent = true; _isLoading = false; });
        _animController.reset();
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() { _errorMessage = widget.loc.isMalayalam ? 'ദയവായി 6 അക്ക ഒ.ടി.പി നൽകുക.' : 'Please enter the 6-digit OTP code.'; });
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await widget.authService.verifyOtp(otpCode: otp);
      if (mounted) { setState(() => _isLoading = false); widget.onAuthenticated(); }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final isMl = loc.isMalayalam;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 880;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: isDesktop ? _buildDesktopLayout(loc, isMl) : _buildMobileLayout(loc, isMl),
    );
  }

  Widget _buildDesktopLayout(LocalizationService loc, bool isMl) {
    return Row(
      children: [
        SizedBox(width: 420, child: _buildHeroPanel(loc, isMl)),
        Expanded(
          child: Stack(
            children: [
              Positioned(
                top: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(children: [
                    IconButton(tooltip: loc.tr('highContrast'), icon: Icon(widget.controller.highContrast ? Icons.contrast : Icons.contrast_outlined, color: const Color(0xFF64748B)), onPressed: () => widget.controller.toggleHighContrast()),
                    IconButton(tooltip: loc.tr('fontSize'), icon: Icon(widget.controller.largeText ? Icons.text_fields : Icons.format_size, color: const Color(0xFF64748B)), onPressed: () => widget.controller.toggleLargeText()),
                    LanguageSelector(loc: loc),
                  ]),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(48, 72, 48, 48),
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: _buildFormArea(isMl)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(LocalizationService loc, bool isMl) {
    return Column(
      children: [
        _buildMobileHeroBar(loc, isMl),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: _buildFormArea(isMl),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPanel(LocalizationService loc, bool isMl) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004E59), Color(0xFF006D77), Color(0xFF00919E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                ),
                child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 32),
              Text(loc.tr('appTitle'), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 0.3, height: 1.1)),
              const SizedBox(height: 10),
              Text('Kerala Social Security Mission', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13.5, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
              const SizedBox(height: 40),
              _buildHeroFeature(Icons.how_to_reg_rounded, isMl ? 'ഒരിക്കൽ ലോഗിൻ, എപ്പോഴും ആക്സസ്' : 'Sign in once, access anytime'),
              const SizedBox(height: 18),
              _buildHeroFeature(Icons.schema_rounded, isMl ? '16 ക്ഷേമ പദ്ധതികൾ — സ്ഥിരീകരിച്ചത്' : '16 verified welfare schemes'),
              const SizedBox(height: 18),
              _buildHeroFeature(Icons.lock_outline_rounded, isMl ? 'നിങ്ങളുടെ ഡേറ്റ സുരക്ഷിതം' : 'Your data, securely protected'),
              const SizedBox(height: 18),
              _buildHeroFeature(Icons.language_rounded, isMl ? 'മലയാളം / ഇംഗ്ലീഷ് ഭാഷ' : 'Malayalam & English support'),
              const Spacer(),
              Row(children: [
                _buildSectorPill(Icons.phishing_rounded, isMl ? 'മത്സ്യം' : 'Fisherfolk'),
                const SizedBox(width: 8),
                _buildSectorPill(Icons.eco_rounded, isMl ? 'തോട്ടം' : 'Plantation'),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: 0.7), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    isMl ? 'ഇത് ഒരു ഔദ്യോഗിക ആനുകൂല്യ അനുമതിയോ ഗവൺമെന്റ് ID ഉം അല്ല.' : 'This is not an official benefit approval or government ID.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, height: 1.4),
                  )),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroFeature(IconData icon, String text) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: const Color(0xFFFFD166), size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500))),
    ]);
  }

  Widget _buildSectorPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: const Color(0xFFFFD166), size: 15),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildMobileHeroBar(LocalizationService loc, bool isMl) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF004E59), Color(0xFF006D77)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(loc.tr('appTitle'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Text('Kerala Social Security Mission', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5)),
        ])),
        LanguageSelector(loc: loc),
        IconButton(icon: Icon(widget.controller.highContrast ? Icons.contrast : Icons.contrast_outlined, color: Colors.white.withValues(alpha: 0.8), size: 20), onPressed: () => widget.controller.toggleHighContrast()),
      ]),
    );
  }

  Widget _buildFormArea(bool isMl) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _otpSent ? (isMl ? 'OTP സ്ഥിരീകരിക്കുക' : 'Verify OTP') : (isMl ? 'ലോഗിൻ ചെയ്യുക' : 'Sign In'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            _otpSent ? (isMl ? 'നിങ്ങളുടെ ഫോണിൽ ലഭിച്ച 6 അക്ക കോഡ് നൽകുക' : 'Enter the 6-digit code sent to your phone') : (isMl ? 'നിങ്ങളുടെ 10 അക്ക മൊബൈൽ നമ്പർ നൽകുക' : 'Enter your 10-digit mobile number to continue'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 32),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFCA5A5))),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w600))),
                GestureDetector(onTap: () => setState(() => _errorMessage = null), child: const Icon(Icons.close, color: Color(0xFFDC2626), size: 18)),
              ]),
            ),
          ],

          if (!_otpSent) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1.5))),
                  child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF006D77))),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    enabled: !_isLoading,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    decoration: InputDecoration(
                      hintText: isMl ? 'മൊബൈൽ നമ്പർ' : 'Mobile Number',
                      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.normal),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _handleSendOtp(),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSendOtp,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006D77), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.sms_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(isMl ? 'OTP അയക്കുക' : 'Send OTP Code', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: const Color(0xFFE0F7F4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF006D77).withValues(alpha: 0.3))),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF006D77), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('${isMl ? "കോഡ് അയച്ചു:" : "Code sent to:"} +91 ${_phoneController.text.trim()}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF004D40)))),
                TextButton(onPressed: _isLoading ? null : () { setState(() { _otpSent = false; _otpController.clear(); _errorMessage = null; }); _animController.reset(); _animController.forward(); }, style: TextButton.styleFrom(foregroundColor: const Color(0xFF006D77)), child: Text(isMl ? 'മാറ്റുക' : 'Change')),
              ]),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6, enabled: !_isLoading, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, letterSpacing: 12, fontWeight: FontWeight.bold, color: Color(0xFF006D77)),
                decoration: InputDecoration(hintText: '• • • • • •', hintStyle: TextStyle(letterSpacing: 8, color: const Color(0xFF006D77).withValues(alpha: 0.3), fontSize: 22), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), counterText: ''),
                onSubmitted: (_) => _handleVerifyOtp(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerifyOtp,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006D77), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.verified_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(isMl ? 'സ്ഥിരീകരിച്ച് തുടരുക' : 'Verify & Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () { _otpController.text = '123456'; _handleVerifyOtp(); },
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF006D77), side: const BorderSide(color: Color(0xFF006D77), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.flash_on_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(isMl ? 'ഡെമോ കോഡ് (123456) ഉപയോഗിക്കുക' : 'Use Evaluation Code (123456)', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                isMl ? 'ഡെമോ: ഏതെങ്കിലും 10 അക്ക നമ്പർ നൽകി, 123456 കോഡ് ഉപയോഗിക്കുക.' : 'Demo Tip: Enter any 10-digit number and use evaluation code 123456.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}
