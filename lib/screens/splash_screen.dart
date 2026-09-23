import 'package:flutter/material.dart';
import '../services/localization_service.dart';

/// Clean, high-performance splash and authentication check screen.
///
/// Prevents navigation flickering and premature home screen rendering
/// while Firebase Auth verifies cached tokens or network state.
class SplashScreen extends StatelessWidget {
  final LocalizationService loc;

  const SplashScreen({
    super.key,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final isMl = loc.isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                : [const Color(0xFF006D77), const Color(0xFF0F4C5C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                loc.tr('appTitle'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isMl ? 'തോട്ടം & മത്സ്യത്തൊഴിലാളി ക്ഷേമസഹായി' : 'Plantation & Fisherfolk Welfare Assistant',
                style: TextStyle(
                  color: isDark ? const Color(0xFFFFD166) : const Color(0xFFFFDDD2),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isMl ? 'അക്കൗണ്ട് വിവരങ്ങൾ പരിശോധിക്കുന്നു...' : 'Checking session...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
