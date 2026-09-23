import 'package:flutter/material.dart';
import '../controllers/alert_controller.dart';
import '../controllers/screening_controller.dart';
import '../models/household_profile.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/scheme_repository.dart';
import '../widgets/language_selector.dart';
import 'auth_dialog.dart';

/// Redesigned modern, professional, hackathon-ready Welfare Saathi Homepage.
///
/// Designed to emulate an authoritative Kerala public-service welfare portal:
/// - Trustworthy deep petrol teal & crisp slate visual language.
/// - Prominent two-column hero with deterministic screening card.
/// - Non-alarming, reassuring statutory legal disclaimer.
/// - 4 Quick-access public service cards (Schemes, Alerts, Akshaya, Profile).
/// - Interactive benchmark/sample profile cards for evaluators.
/// - Preserves 100% of existing authentication, profile persistence, and screening logic.
class WelcomeScreen extends StatefulWidget {
  final ScreeningController controller;
  final LocalizationService loc;
  final VoidCallback onStartScreening;
  final VoidCallback onSampleLoaded;
  final VoidCallback onOpenDirectory;
  final AlertController? alertController;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onReviewProfile;
  final AuthService? authService;

  const WelcomeScreen({
    super.key,
    required this.controller,
    required this.loc,
    required this.onStartScreening,
    required this.onSampleLoaded,
    required this.onOpenDirectory,
    this.alertController,
    this.onOpenAlerts,
    this.onReviewProfile,
    this.authService,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  HouseholdProfile? _savedProfile;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    widget.authService?.addListener(_onAuthChanged);
    _checkAndLoadProfile();
  }

  @override
  void didUpdateWidget(covariant WelcomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authService != widget.authService) {
      oldWidget.authService?.removeListener(_onAuthChanged);
      widget.authService?.addListener(_onAuthChanged);
      _checkAndLoadProfile();
    }
  }

  @override
  void dispose() {
    widget.authService?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    _checkAndLoadProfile();
  }

  Future<void> _checkAndLoadProfile() async {
    final auth = widget.authService;
    if (auth != null && auth.isAuthenticated) {
      setState(() => _isLoadingProfile = true);
      try {
        final profile = await widget.controller.loadProfileFromRemote();
        if (mounted) {
          setState(() {
            _savedProfile = profile;
            _isLoadingProfile = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoadingProfile = false);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _savedProfile = null;
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _openAuthDialog() {
    if (widget.authService == null) return;
    AuthDialog.show(
      context: context,
      authService: widget.authService!,
      loc: widget.loc,
      onAuthenticated: () {
        _checkAndLoadProfile();
      },
    );
  }

  void _confirmSignOut() {
    final loc = widget.loc;
    final isMl = loc.isMalayalam;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMl ? 'ലോഗ് ഔട്ട് ചെയ്യണോ?' : 'Sign Out?'),
        content: Text(
          isMl
              ? 'നിങ്ങൾ ലോഗ് ഔട്ട് ചെയ്താൽ നിങ്ങളുടെ വിവരങ്ങൾ ഇവിടെ നിന്ന് ഒഴിവാകും. അടുത്ത തവണ ലോഗിൻ ചെയ്യുമ്പോൾ വീണ്ടും ലഭിക്കുന്നതാണ്.'
              : 'Signing out will clear the active in-memory session. Your profile remains safely stored in the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.authService?.signOut();
              widget.controller.reset();
              _checkAndLoadProfile();
            },
            child: Text(isMl ? 'ലോഗ് ഔട്ട്' : 'Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final loc = widget.loc;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;
    final isTablet = screenWidth >= 640 && screenWidth < 960;
    final isMobile = screenWidth < 640;
    final isMl = loc.isMalayalam;
    final auth = widget.authService;
    final isAuthenticated = auth?.isAuthenticated ?? false;
    final currentUser = auth?.currentUser;

    return Scaffold(
      appBar: _buildTopNavigationBar(
        context,
        loc,
        isMl,
        isDark,
        isDesktop,
        isMobile,
        controller,
        auth,
        isAuthenticated,
        currentUser,
        theme,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 36 : (isTablet ? 24 : 16),
          vertical: isDesktop ? 28 : 18,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HERO SECTION (Wide 2-column on desktop, stacked on mobile)
                _buildHeroSection(
                  context,
                  loc,
                  isMl,
                  isDark,
                  isDesktop,
                  controller,
                  isAuthenticated,
                  theme,
                ),

                const SizedBox(height: 24),

                // 2. TRUST / STATUTORY DISCLAIMER SECTION
                _buildTrustDisclaimerSection(loc, isMl, isDark, theme),

                const SizedBox(height: 28),

                // 3. QUICK ACCESS HUBS (4 Modern Cards)
                _buildQuickAccessSection(context, loc, isMl, isDark, isDesktop, theme),

                const SizedBox(height: 32),

                // 4. SAMPLE / BENCHMARK PROFILES (Interactive evaluation cards)
                _buildSampleProfilesSection(controller, loc, isMl, isDark, theme),

                const SizedBox(height: 36),

                // 5. PUBLIC SERVICE FOOTER
                _buildPortalFooter(isMl, isDark, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP NAVIGATION BAR (Authoritative, Accessible, Responsive)
  // ===========================================================================
  PreferredSizeWidget _buildTopNavigationBar(
    BuildContext context,
    LocalizationService loc,
    bool isMl,
    bool isDark,
    bool isDesktop,
    bool isMobile,
    ScreeningController controller,
    AuthService? auth,
    bool isAuthenticated,
    AppUser? currentUser,
    ThemeData theme,
  ) {
    return AppBar(
      automaticallyImplyLeading: false, // Explicitly no Back button on Homepage
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: isMobile ? 12 : 24,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Portal Emblem / Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        loc.tr('appTitle'),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 15 : 18,
                          letterSpacing: 0.2,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PORTAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  isMl ? 'കേരള സാമൂഹിക സുരക്ഷാ പോർട്ടൽ' : 'Kerala Social Security Discovery Portal',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: !isDesktop
          ? [
              if (auth != null && isAuthenticated)
                PopupMenuButton<String>(
                  tooltip: isMl ? 'അക്കൗണ്ട്' : 'Account',
                  icon: Icon(
                    Icons.account_circle_outlined,
                    size: 20,
                    color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                  ),
                  onSelected: (val) {
                    if (val == 'signout') _confirmSignOut();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        currentUser?.maskedPhoneNumber ?? (isMl ? 'അക്കൗണ്ട്' : 'Account'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'signout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isMl ? 'ലോഗ് ഔട്ട് (Sign Out)' : 'Sign Out',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              IconButton(
                tooltip: loc.tr('schemeDirectory'),
                icon: const Icon(Icons.menu_book_rounded),
                onPressed: widget.onOpenDirectory,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'contrast') controller.toggleHighContrast();
                  if (val == 'font') controller.toggleLargeText();
                  if (val == 'alerts' && widget.onOpenAlerts != null) widget.onOpenAlerts!();
                },
                itemBuilder: (ctx) => [
                  if (widget.onOpenAlerts != null)
                    PopupMenuItem(
                      value: 'alerts',
                      child: Row(
                        children: [
                          Badge(
                            isLabelVisible: (widget.alertController?.unreadCount ?? 0) > 0,
                            label: Text('${widget.alertController?.unreadCount ?? 0}'),
                            child: const Icon(Icons.shield_outlined, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(loc.tr('safetyAlerts')),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'contrast',
                    child: Row(
                      children: [
                        Icon(controller.highContrast ? Icons.contrast : Icons.contrast_outlined, size: 20),
                        const SizedBox(width: 10),
                        Text(loc.tr('highContrast')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'font',
                    child: Row(
                      children: [
                        Icon(controller.largeText ? Icons.text_fields : Icons.format_size, size: 20),
                        const SizedBox(width: 10),
                        Text(loc.tr('fontSize')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              LanguageSelector(loc: loc, compact: true),
              const SizedBox(width: 10),
            ]
          : [
              // Notification / Safety Advisory Icon
              if (widget.onOpenAlerts != null)
                IconButton(
                  tooltip: isMl ? 'സുരക്ഷാ മുന്നറിയിപ്പുകൾ' : 'Safety Advisories',
                  icon: Badge(
                    isLabelVisible: (widget.alertController?.unreadCount ?? 0) > 0,
                    label: Text('${widget.alertController?.unreadCount ?? 0}'),
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                  onPressed: widget.onOpenAlerts,
                ),

              // Handbook / Scheme Directory Button
              TextButton.icon(
                onPressed: widget.onOpenDirectory,
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: Text(
                  isMl ? 'പദ്ധതി വിവരങ്ങൾ' : 'Handbook',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),

              // High Contrast Accessibility Toggle
              IconButton(
                tooltip: loc.tr('highContrast'),
                icon: Icon(controller.highContrast ? Icons.contrast : Icons.contrast_outlined),
                onPressed: () => controller.toggleHighContrast(),
              ),

              // Font Size Toggle
              IconButton(
                tooltip: loc.tr('fontSize'),
                icon: Icon(controller.largeText ? Icons.text_fields : Icons.format_size),
                onPressed: () => controller.toggleLargeText(),
              ),

              // User Account / Profile Dropdown
              if (auth != null)
                if (isAuthenticated)
                  PopupMenuButton<String>(
                    tooltip: isMl ? 'അക്കൗണ്ട്' : 'Account',
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF333333) : const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            size: 16,
                            color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isMl ? 'അക്കൗണ്ട്' : 'Account',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF004D40),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ),
                    ),
                    onSelected: (val) {
                      if (val == 'signout') _confirmSignOut();
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.maskedPhoneNumber ?? (isMl ? 'അക്കൗണ്ട്' : 'Account'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isMl
                                  ? 'പരിശോധിച്ച ഫോൺ നമ്പർ'
                                  : 'Verified Mobile',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'signout',
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              isMl ? 'ലോഗ് ഔട്ട് (Sign Out)' : 'Sign Out',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  TextButton.icon(
                    icon: const Icon(Icons.lock_person_outlined, size: 18),
                    label: Text(
                      isMl ? 'ലോഗിൻ' : 'Sign In',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _openAuthDialog,
                  ),

              const SizedBox(width: 6),
              LanguageSelector(loc: loc),
              const SizedBox(width: 18),
            ],
    );
  }

  // ===========================================================================
  // 2. HERO SECTION (Deep Petrol Teal Left Column + Crisp Screening Card Right)
  // ===========================================================================
  Widget _buildHeroSection(
    BuildContext context,
    LocalizationService loc,
    bool isMl,
    bool isDark,
    bool isDesktop,
    ScreeningController controller,
    bool isAuthenticated,
    ThemeData theme,
  ) {
    final leftHero = Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF161E22), const Color(0xFF0F171A)]
              : [const Color(0xFF005662), const Color(0xFF003840)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFF004953),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top State Initiative Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_moon_outlined,
                  color: Color(0xFFFFD166),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isMl
                        ? 'കേരള സാമൂഹിക സുരക്ഷാ സഹായം'
                        : 'KERALA SOCIAL SECURITY ASSISTANCE',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Portal Title
          Text(
            loc.tr('appTitle'),
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 34 : 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 6),

          // Subtitle
          Text(
            isMl ? 'തോട്ടം & മത്സ്യത്തൊഴിലാളി ക്ഷേമസഹായി' : 'Plantation & Fisherfolk Welfare Assistant',
            style: const TextStyle(
              color: Color(0xFFFFDDD2),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          // Main Message
          Text(
            isMl
                ? 'നിങ്ങളുടെ കുടുംബത്തിന് അർഹതയുണ്ടാകാൻ സാധ്യതയുള്ള ക്ഷേമപദ്ധതികൾ കണ്ടെത്തുക.'
                : 'Find welfare schemes that your household may potentially qualify for.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 10),

          // Supporting Text
          Text(
            isMl
                ? 'കേരളത്തിലെ തീരദേശ മത്സ്യത്തൊഴിലാളി, മലയോര തോട്ടം തൊഴിലാളി കുടുംബങ്ങൾക്കായി ക്ഷേമനിധി പെൻഷനുകൾ, വിദ്യാഭ്യാസ സഹായം, പ്രസവാനുകൂല്യം, ഭവന പദ്ധതികൾ എന്നിവ ലളിതമായി കണ്ടെത്താൻ വെൽഫെയർ സാഥി സഹായിക്കുന്നു.'
                : 'Welfare Saathi helps coastal fishing and hill plantation communities in Kerala easily discover statutory welfare board pensions, education grants, maternity benefits, and housing support with verified guidance.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 24),

          // Feature Indicators (Chips)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroFeatureChip(
                icon: Icons.menu_book_rounded,
                label: '16 Scheme Definitions',
              ),
              _buildHeroFeatureChip(
                icon: Icons.rule_folder_rounded,
                label: 'Deterministic Rule Evaluation',
              ),
              _buildHeroFeatureChip(
                icon: Icons.lock_outline_rounded,
                label: 'Privacy-Conscious Screening',
              ),
            ],
          ),
        ],
      ),
    );

    final rightCard = _buildHouseholdScreeningCard(
      context,
      loc,
      isMl,
      isDark,
      controller,
      isAuthenticated,
      theme,
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: leftHero),
          const SizedBox(width: 28),
          Expanded(flex: 5, child: rightCard),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftHero,
          const SizedBox(height: 20),
          rightCard,
        ],
      );
    }
  }

  Widget _buildHeroFeatureChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFFD166)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HOUSEHOLD SCREENING CARD (Right Hero Side)
  // ===========================================================================
  Widget _buildHouseholdScreeningCard(
    BuildContext context,
    LocalizationService loc,
    bool isMl,
    bool isDark,
    ScreeningController controller,
    bool isAuthenticated,
    ThemeData theme,
  ) {
    if (_isLoadingProfile) {
      return Container(
        height: 340,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // RETURNING USER WITH SAVED PROFILE
    if (isAuthenticated && _savedProfile != null) {
      return _buildReturningUserScreeningCard(context, _savedProfile!, isMl, isDark, theme);
    }

    // GUEST / NEW USER SCREENING CARD
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.how_to_reg_rounded,
                  color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMl ? 'കുടുംബ വിവരങ്ങൾ പരിശോധിക്കുക' : 'Check Your Household',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMl ? '3 ഘട്ടങ്ങളിലായി ലളിതമായ ചോദ്യങ്ങൾ' : 'Fast 3-step entitlement screening',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            isMl
                ? 'നിങ്ങളുടെ കുടുംബത്തിന് അനുയോജ്യമായ സർക്കാർ ക്ഷേമപദ്ധതികൾ കണ്ടെത്താൻ ലളിതമായ ഏതാനും ചോദ്യങ്ങൾക്ക് മറുപടി നൽകുക.'
                : 'Answer a few questions to discover welfare schemes that may be relevant to your household.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),

          const SizedBox(height: 24),

          // Primary Button: Start Screening
          ElevatedButton.icon(
            onPressed: () {
              controller.startNewScreening();
              widget.onStartScreening();
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(
              loc.tr('startScreening'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 12),

          // Secondary Option: Browse Schemes
          OutlinedButton.icon(
            onPressed: widget.onOpenDirectory,
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: Text(
              isMl
                  ? 'എല്ലാ 16 ക്ഷേമപദ്ധതികളും കാണുക (Browse All 16 Verified Schemes)'
                  : 'Browse All 16 Verified Schemes & Handbook',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 16),

          // Sign In Helper Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF404040) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_sync_outlined,
                  size: 18,
                  color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isMl
                        ? 'മൊബൈൽ നമ്പർ വഴി ലോഗിൻ ചെയ്ത് വിവരങ്ങൾ സൂക്ഷിക്കാം.'
                        : 'Sign in with phone number to save results across visits.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                if (!isAuthenticated)
                  TextButton(
                    onPressed: _openAuthDialog,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      isMl ? 'ലോഗിൻ' : 'Sign In',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturningUserScreeningCard(
    BuildContext context,
    HouseholdProfile profile,
    bool isMl,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2824) : const Color(0xFFF0FDF4),
        border: Border.all(
          color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMl
                          ? 'നിങ്ങളുടെ കുടുംബ വിവരങ്ങൾ ലഭ്യമാണ്'
                          : 'Your household profile is available',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Account: ${widget.authService?.currentUser?.maskedPhoneNumber ?? (isMl ? 'ലോഗിൻ ചെയ്തിട്ടുണ്ട്' : 'Signed In')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Summary Badges
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildSummaryBadge(
                  label: isMl ? 'തൊഴിൽ' : 'Work',
                  value: _formatOccupation(profile.occupation, isMl),
                  icon: Icons.work_outline_rounded,
                ),
                _buildSummaryBadge(
                  label: isMl ? 'ജില്ല' : 'District',
                  value: profile.district ?? (isMl ? 'തിരഞ്ഞെടുത്തട്ടില്ല' : 'Not set'),
                  icon: Icons.location_on_outlined,
                ),
                if (profile.age != null)
                  _buildSummaryBadge(
                    label: isMl ? 'പ്രായം' : 'Age',
                    value: '${profile.age} ${isMl ? 'വയസ്സ്' : 'yrs'}',
                    icon: Icons.cake_outlined,
                  ),
                if (profile.monthlyIncome != null)
                  _buildSummaryBadge(
                    label: isMl ? 'വരുമാനം' : 'Income',
                    value: '₹${profile.monthlyIncome}/mo',
                    icon: Icons.currency_rupee_rounded,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Button 1: Review My Details
          ElevatedButton.icon(
            onPressed: () {
              widget.controller.editSavedProfile(profile);
              if (widget.onReviewProfile != null) {
                widget.onReviewProfile!();
              } else {
                widget.controller.setStep(0);
                widget.onStartScreening();
              }
            },
            icon: const Icon(Icons.rate_review_rounded, size: 20),
            label: Text(
              isMl ? 'വിവരങ്ങൾ പരിശോധിക്കുക (Review My Details)' : 'Review My Details',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 10),

          // Button 2: Continue with Saved Details
          OutlinedButton.icon(
            onPressed: () {
              widget.controller.continueWithSavedProfile(profile);
              widget.onSampleLoaded();
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
              isMl ? 'നേരിട്ട് പരിശോധനാ ഫലങ്ങൾ കാണുക' : 'Continue with Saved Details',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 8),

          // Button 3: Start New Screening (Clean Session)
          TextButton.icon(
            onPressed: () {
              widget.controller.startNewScreening();
              widget.onStartScreening();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              isMl ? 'പുതിയ പരിശോധന ആരംഭിക്കുക (Start New Screening)' : 'Start New Screening (Clean Session)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. TRUST / STATUTORY DISCLAIMER SECTION (Non-Alarming, Reassuring)
  // ===========================================================================
  Widget _buildTrustDisclaimerSection(
    LocalizationService loc,
    bool isMl,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262016) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_outlined,
            color: isDark ? const Color(0xFFFFD166) : const Color(0xFFD97706),
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMl ? 'സാധ്യതയുള്ള അർഹത മാത്രം (Potential Eligibility Only)' : 'Potential Eligibility Only',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFFD166) : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMl
                      ? 'ഈ പോർട്ടലിലെ ഫലങ്ങൾ നിർദ്ദേശിക്കപ്പെട്ട മാനദണ്ഡങ്ങൾ അടിസ്ഥാനമാക്കിയുള്ള സാധ്യതാ വിവരങ്ങൾ മാത്രമാണ്. അന്തിമ അർഹത ബന്ധപ്പെട്ട സർക്കാർ ഉദ്യോഗസ്ഥർ നിശ്ചയിക്കുന്നതാണ്.'
                      : 'Results are potential eligibility indications based on the supplied scheme rules. Final eligibility is determined by the relevant authority.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark ? const Color(0xFFFFE8A3) : const Color(0xFF78350F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. QUICK ACCESS HUBS (4 Modern Public Service Cards)
  // ===========================================================================
  Widget _buildQuickAccessSection(
    BuildContext context,
    LocalizationService loc,
    bool isMl,
    bool isDark,
    bool isDesktop,
    ThemeData theme,
  ) {
    final cards = [
      _buildHubCard(
        context: context,
        title: isMl ? 'പദ്ധതി വിവരങ്ങൾ' : 'Browse Welfare Schemes',
        subtitle: isMl ? 'എല്ലാ 16 ക്ഷേമപദ്ധതികളും' : '16 Scheme Definitions',
        description: isMl
            ? 'ലഭ്യമായ പദ്ധതികളും അർഹതാ മാനദണ്ഡങ്ങളും പരിശോധിക്കുക.'
            : 'Explore available schemes and eligibility requirements.',
        icon: Icons.menu_book_rounded,
        iconColor: const Color(0xFF006D77),
        badgeText: null,
        onTap: widget.onOpenDirectory,
        isDark: isDark,
        theme: theme,
      ),
      _buildHubCard(
        context: context,
        title: isMl ? 'സുരക്ഷാ മുന്നറിയിപ്പുകൾ' : 'Community Safety Alerts',
        subtitle: isMl ? 'തീരദേശ & മലയോര ജാഗ്രത' : 'Coastal & Hill Advisories',
        description: isMl
            ? 'കാലാവസ്ഥാ മുന്നറിയിപ്പുകളും സുരക്ഷാ നിർദ്ദേശങ്ങളും കാണുക.'
            : 'View coastal and hill/plantation safety advisories.',
        icon: Icons.shield_rounded,
        iconColor: const Color(0xFFD97706),
        badgeText: 'DEMO',
        onTap: widget.onOpenAlerts ?? () {},
        isDark: isDark,
        theme: theme,
      ),
      _buildHubCard(
        context: context,
        title: isMl ? 'അക്ഷയ കേന്ദ്ര റിപ്പോർട്ട്' : 'Prepare Akshaya Report',
        subtitle: isMl ? 'ഓഫ്‌ലൈൻ വെരിഫിക്കേഷൻ' : 'Facilitated Desk PDF',
        description: isMl
            ? 'അക്ഷയ കേന്ദ്രത്തിലെ സേവനത്തിനായി സത്യപ്രസ്താവനയും റിപ്പോർട്ടും തയാറാക്കുക.'
            : 'Prepare a screening summary for assistance at an Akshaya centre.',
        icon: Icons.picture_as_pdf_rounded,
        iconColor: const Color(0xFF2563EB),
        badgeText: null,
        onTap: () {
          widget.controller.startNewScreening();
          widget.onStartScreening();
        },
        isDark: isDark,
        theme: theme,
      ),
      _buildHubCard(
        context: context,
        title: isMl ? 'എന്റെ കുടുംബ വിവരങ്ങൾ' : 'My Household Profile',
        subtitle: isMl ? 'ക്ലൗഡ് സംഭരണം' : 'Secure Cloud Storage',
        description: isMl
            ? 'സേവ് ചെയ്ത വിവരങ്ങൾ കാണാനും ആവശ്യാനുസരണം മാറ്റാനും.'
            : 'View or update your saved household information.',
        icon: Icons.account_circle_rounded,
        iconColor: const Color(0xFF059669),
        badgeText: null,
        onTap: () {
          if (widget.authService != null && widget.authService!.isAuthenticated) {
            if (_savedProfile != null) {
              widget.controller.editSavedProfile(_savedProfile!);
              if (widget.onReviewProfile != null) {
                widget.onReviewProfile!();
              } else {
                widget.controller.setStep(0);
                widget.onStartScreening();
              }
            } else {
              widget.controller.startNewScreening();
              widget.onStartScreening();
            }
          } else {
            _openAuthDialog();
          }
        },
        isDark: isDark,
        theme: theme,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isMl ? 'പ്രധാന സേവനങ്ങൾ' : 'Quick Access Hub',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 960) {
              // 4 columns on large desktop
              return Row(
                children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
              );
            } else if (constraints.maxWidth >= 600) {
              // 2x2 grid on tablets
              return Column(
                children: [
                  Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
                  const SizedBox(height: 12),
                  Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
                ],
              );
            } else {
              // Single vertical stack on mobile
              return Column(
                children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildHubCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String? badgeText,
    required VoidCallback onTap,
    required bool isDark,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF856404), width: 0.6),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF856404),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. SAMPLE / BENCHMARK PROFILES SECTION
  // ===========================================================================
  Widget _buildSampleProfilesSection(
    ScreeningController controller,
    LocalizationService loc,
    bool isMl,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMl ? 'സാമ്പിൾ പ്രൊഫൈലുകൾ പരീക്ഷിക്കുക' : 'Try a Sample Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    isMl
                        ? 'വിവിധ കുടുംബ സാഹചര്യങ്ങൾ വെൽഫെയർ സാഥി എങ്ങനെ വിലയിരുത്തുന്നു എന്ന് പരിശോധിക്കുക.'
                        : 'Explore how Welfare Saathi evaluates different household situations.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...controller.repository.sampleProfiles.map((sample) {
          return _buildSampleProfileCard(sample, controller, isMl, isDark, theme);
        }),
      ],
    );
  }

  Widget _buildSampleProfileCard(
    SampleProfileItem sample,
    ScreeningController controller,
    bool isMl,
    bool isDark,
    ThemeData theme,
  ) {
    final occ = sample.profile.occupation;
    IconData icon;
    Color iconColor;
    if (occ == 'fishing') {
      icon = Icons.phishing_rounded;
      iconColor = const Color(0xFF006D77);
    } else if (occ == 'plantation') {
      icon = Icons.eco_rounded;
      iconColor = const Color(0xFF059669);
    } else {
      icon = Icons.work_outline_rounded;
      iconColor = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: isDark ? const Color(0xFFFFD166) : iconColor, size: 22),
        ),
        title: Text(
          sample.getTitle(isMl),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            sample.getDescription(isMl),
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        trailing: FilledButton.tonal(
          onPressed: () {
            controller.loadSampleProfile(sample);
            widget.onSampleLoaded();
          },
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMl ? 'പരിശോധിക്കുക' : 'Evaluate',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. PUBLIC SERVICE FOOTER
  // ===========================================================================
  Widget _buildPortalFooter(bool isMl, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Icon(
                Icons.account_balance_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              Text(
                isMl
                    ? 'ക്ഷേമനിധി ബോർഡ് വിവര സഹായ പോർട്ടൽ'
                    : 'Kerala Social Security Discovery Portal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isMl
                ? 'അക്ഷയ ഇ-കേന്ദ്രങ്ങൾ വഴി അപേക്ഷാ സമർപ്പണത്തിന് സഹായം ലഭ്യമാണ്. വിവരങ്ങൾ സ്വകാര്യമായി സൂക്ഷിക്കപ്പെടുന്നു.'
                : 'Facilitation for Akshaya e-Centres & Village Offices. Evaluated deterministically with privacy-first storage.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BADGES & FORMATTING HELPERS
  // ===========================================================================
  Widget _buildSummaryBadge({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF006D77).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF006D77)),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatOccupation(String? occ, bool isMl) {
    if (occ == 'fishing') {
      return isMl ? 'മത്സ്യത്തൊഴിലാളി' : 'Fishing';
    } else if (occ == 'plantation') {
      return isMl ? 'തോട്ടം തൊഴിലാളി' : 'Plantation';
    } else if (occ == 'other') {
      return isMl ? 'മറ്റ് തൊഴിൽ' : 'Other';
    }
    return isMl ? 'തിരഞ്ഞെടുത്തട്ടില്ല' : 'Not set';
  }
}
