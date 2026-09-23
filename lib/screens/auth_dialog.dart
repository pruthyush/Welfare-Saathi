import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';

/// Modal dialog for user authentication (Login / Sign Up).
///
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
  bool _isSignUp = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await widget.authService.signUpWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await widget.authService.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onAuthenticated();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                        Icons.lock_person_rounded,
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
                            _isSignUp
                                ? (isMl ? 'പുതിയ അക്കൗണ്ട് തുറക്കുക' : 'Create User Account')
                                : (isMl ? 'ലോഗിൻ ചെയ്യുക' : 'Sign In to Welfare Saathi'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMl
                                ? 'നിങ്ങളുടെ വിവരങ്ങൾ സംരക്ഷിക്കാൻ'
                                : 'Save & retrieve household screening answers',
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

                // Email Field
                Text(
                  isMl ? 'ഇമെയിൽ വിലാസം' : 'Email Address',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return isMl ? 'ഇമെയിൽ നൽകുക' : 'Please enter email';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return isMl ? 'ശരിയായ ഇമെയിൽ നൽകുക' : 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password Field
                Text(
                  isMl ? 'പാസ്‌വേഡ്' : 'Password',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return isMl ? 'പാസ്‌വേഡ് നൽകുക' : 'Please enter password';
                    }
                    if (val.length < 6) {
                      return isMl ? 'കുറഞ്ഞത് 6 അക്ഷരങ്ങൾ വേണം' : 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
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
                          _isSignUp
                              ? (isMl ? 'രജിസ്റ്റർ ചെയ്യുക' : 'Create Account')
                              : (isMl ? 'പ്രവേശിക്കുക (Sign In)' : 'Sign In'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),

                // Switch between Login and Sign Up
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? (isMl
                            ? 'ഇതിനകം അക്കൗണ്ട് ഉണ്ടോ? പ്രവേശിക്കുക'
                            : 'Already have an account? Sign In')
                        : (isMl
                            ? 'പുതിയ ഉപയോക്താവാണോ? അക്കൗണ്ട് തുറക്കുക'
                            : "New user? Create an account"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
