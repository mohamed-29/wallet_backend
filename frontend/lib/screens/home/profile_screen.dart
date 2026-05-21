import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import 'edit_profile_screen.dart';
// import 'top_up_screen.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsOn = true;
  bool _darkModeOn = false;
  bool _biometricOn = true;

  final ScrollController _scrollCtrl = ScrollController();
  double _collapseProgress = 0.0;
  static const double _expandedHeight = 260.0;
  static const double _fadeStart = 130.0;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn));
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
    _scrollCtrl.addListener(_onScroll);

    // Update user data from transactions
    final user = Provider.of<User>(context, listen: false);
    Future.delayed(Duration.zero, () {
      user.updateFromTransactions(mockTransactions);
    });
  }

  void _onScroll() {
    final offset = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
    final progress = ((offset - _fadeStart) / (_expandedHeight - _fadeStart))
        .clamp(0.0, 1.0);
    if (progress != _collapseProgress) {
      setState(() => _collapseProgress = progress);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // Hero header — expands, collapses to pinned navy bar, blurs on stretch
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            automaticallyImplyLeading: false,
            toolbarHeight: 0,
            backgroundColor: Color.lerp(
              AppColors.offWhite,
              AppColors.originalCreamMid,
              _collapseProgress,
            ),
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            // title: const Text(
            //   'Profile',
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontSize: 17,
            //     fontWeight: FontWeight.w700,
            //   ),
            // ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.blurBackground],
              background: _ProfileHeader(),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Account section
                      _SectionHeader(title: 'Account'),
                      const SizedBox(height: 10),
                      _SettingsGroup(
                        items: [
                          _SettingsItem(
                            icon: Icons.person_rounded,
                            iconColor: AppColors.navy,
                            title: 'Edit Profile',
                            subtitle: 'Name, phone, email',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            ),
                          ),
                          // _SettingsItem(
                          //   icon: Icons.account_balance_wallet_rounded,
                          //   iconColor: AppColors.orange,
                          //   title: 'Wallet & Payments',
                          //   subtitle:
                          //       'EGP ${user.walletBalance.toStringAsFixed(2)} available',
                          //   badge: 'Top Up',
                          //   badgeColor: AppColors.orange,
                          //   onTap: () => Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (_) => const TopUpScreen(),
                          //     ),
                          //   ),
                          // ),
                          // _SettingsItem(
                          //   icon: Icons.stars_rounded,
                          //   iconColor: AppColors.warning,
                          //   title: 'My Points',
                          //   subtitle:
                          //       '${user.availablePoints} pts · Tier: ${user.tier}',
                          //   onTap: () {},
                          // ),
                          // _SettingsItem(
                          //   icon: Icons.history_rounded,
                          //   iconColor: AppColors.navyMid,
                          //   title: 'Transaction History',
                          //   subtitle: 'View all purchases',
                          //   onTap: () {},
                          // ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Preferences section
                      _SectionHeader(title: 'Preferences'),
                      const SizedBox(height: 10),
                      _SettingsGroup(
                        items: [
                          // _SettingsToggle(
                          //   icon: Icons.notifications_rounded,
                          //   iconColor: AppColors.success,
                          //   title: 'Push Notifications',
                          //   subtitle: 'Offers & order updates',
                          //   value: _notificationsOn,
                          //   onChanged: (v) {
                          //     HapticFeedback.lightImpact();
                          //     setState(() => _notificationsOn = v);
                          //   },
                          // ),
                          // _SettingsToggle(
                          //   icon: Icons.fingerprint_rounded,
                          //   iconColor: AppColors.navy,
                          //   title: 'Biometric Login',
                          //   subtitle: 'Face ID / Touch ID',
                          //   value: _biometricOn,
                          //   onChanged: (v) {
                          //     HapticFeedback.lightImpact();
                          //     setState(() => _biometricOn = v);
                          //   },
                          // ),
                          // _SettingsToggle(
                          //   icon: Icons.dark_mode_rounded,
                          //   iconColor: AppColors.navyMid,
                          //   title: 'Dark Mode',
                          //   subtitle: 'Coming soon',
                          //   value: _darkModeOn,
                          //   onChanged: (v) {
                          //     HapticFeedback.lightImpact();
                          //     setState(() => _darkModeOn = v);
                          //   },
                          // ),
                          _SettingsItem(
                            icon: Icons.language_rounded,
                            iconColor: AppColors.orange,
                            title: 'Language',
                            subtitle: 'English',
                            trailing: const Text(
                              'EN',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // About section
                      _SectionHeader(title: 'About'),
                      const SizedBox(height: 10),
                      _SettingsGroup(
                        items: [
                          // _SettingsItem(
                          //   icon: Icons.shield_rounded,
                          //   iconColor: AppColors.navy,
                          //   title: 'Privacy Policy',
                          //   onTap: () {},
                          // ),
                          // _SettingsItem(
                          //   icon: Icons.description_rounded,
                          //   iconColor: AppColors.navy,
                          //   title: 'Terms of Service',
                          //   onTap: () {},
                          // ),
                          _SettingsItem(
                            icon: Icons.info_rounded,
                            iconColor: AppColors.grey,
                            title: 'About ivend',
                            subtitle: 'Version 1.0.0',
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sign out
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _confirmSignOut(context);
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Sign Out',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'ivend ',
                              style: TextStyle(
                                fontFamily: AppFonts.outfit,
                                color: AppColors.grey.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'by mobica',
                              style: TextStyle(
                                fontFamily: AppFonts.montserrat,
                                color: AppColors.grey.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.aboveBaseline,
                              baseline: TextBaseline.alphabetic,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey.withOpacity(
                                      0.6,
                                    ),
                                    shape: BoxShape.rectangle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            color: AppColors.grey.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign Out?',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will be returned to the sign in screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: AppColors.beige,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      foregroundColor: AppColors.navy,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await UserService.logout();
                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/signin', (route) => false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.originalCream,
            AppColors.originalCreamLight,
            AppColors.originalCreamMid,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, top + 16, 24, 32),
        child: Column(
          children: [
            // Row(
            //   children: [
            //     Container(
            //       width: 44,
            //       height: 44,
            //       decoration: BoxDecoration(
            //         color: AppColors.orange.withOpacity(0.12),
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       child: const Icon(
            //         Icons.person_rounded,
            //         color: AppColors.orange,
            //         size: 24,
            //       ),
            //     ),
            //     const SizedBox(width: 14),
            //     const Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           'Profile',
            //           style: TextStyle(
            //             color: AppColors.navy,
            //             fontSize: 22,
            //             fontWeight: FontWeight.w700,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ],
            // ),
            const SizedBox(height: 23),
            Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.orangeLight, AppColors.orangeDark],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.avatarInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.navy, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phone,
                        style: TextStyle(
                          color: AppColors.navy.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.orangeLight,
                              AppColors.orangeDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        // child: Row(
                        //   mainAxisSize: MainAxisSize.min,
                        //   children: const [
                        //     Icon(
                        //       Icons.workspace_premium_rounded,
                        //       color: Colors.white,
                        //       size: 13,
                        //     ),
                        //     SizedBox(width: 4),
                        //     Text(
                        //       'Gold Member',
                        //       style: TextStyle(
                        //         color: Colors.white,
                        //         fontSize: 11,
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                // _HeaderStat(
                //   label: 'Points',
                //   value: user.availablePoints.toString(),
                // ),
                // _HeaderDivider(),
                _HeaderStat(
                  label: 'Credits',
                  value: 'EGP ${user.walletBalance.toStringAsFixed(2)}',
                ),
                _HeaderDivider(),
                _HeaderStat(
                  label: () {
                    final count = mockTransactions
                        .where((t) =>
                            t.type == TransactionType.purchase &&
                            t.status != 'REFUNDED')
                        .length;
                    return count == 1 ? 'Purchase' : 'Purchases';
                  }(),
                  value: mockTransactions
                      .where((t) =>
                          t.type == TransactionType.purchase &&
                          t.status != 'REFUNDED')
                      .length
                      .toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: value.startsWith('EGP ')
                ? RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'EGP ',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: value.substring(4),
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.navy.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.navy.withOpacity(0.15),
    );
  }
}

// ── Settings Widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.grey.withOpacity(0.7),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 68,
                endIndent: 20,
                color: AppColors.lightGrey,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.badge,
    this.badgeColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.orange).withOpacity(
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: badgeColor ?? AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.grey.withOpacity(0.5),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.orange,
          ),
        ],
      ),
    );
  }
}
