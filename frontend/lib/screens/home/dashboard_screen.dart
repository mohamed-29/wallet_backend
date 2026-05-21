import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../widgets/glass_card.dart';
import '../../services/user_service.dart';
import '../../services/transactions_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const DashboardScreen({super.key, this.onNotificationTap, this.onAvatarTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  final ScrollController _scrollCtrl = ScrollController();
  double _collapseProgress = 0.0;
  List<TransactionModel> _transactions = [];

  static const double _expandedHeight = 355.0;
  // Start the color transition in the last 60px of collapse
  static const double _fadeStart = 177.5;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeIn));
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _headerCtrl.forward();
    _scrollCtrl.addListener(_onScroll);

    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        UserService.fetch(),
        TransactionsService.fetch(),
      ]);
      if (mounted) {
        final userData = results[0] as UserData;
        final transactions = results[1] as List<TransactionModel>;
        Provider.of<User>(context, listen: false).loadFromUserData(userData);
        setState(() {
          _transactions = transactions;
          mockTransactions = transactions;
        });
      }
    } catch (e) {
      print('Fetch Error: $e');
    }
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
    _headerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _headerCtrl.reset();
    _headerCtrl.forward();
    await _fetchData();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);

    // Calculate dynamic stats
    final purchasesCount = _transactions
        .where((tx) =>
            tx.type == TransactionType.purchase && tx.status != 'REFUNDED')
        .length;

    final totalSpent = _transactions
        .where((tx) =>
            tx.type == TransactionType.purchase && tx.status != 'REFUNDED')
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());

    final uniqueMachines = _transactions
        .where((tx) =>
            tx.type == TransactionType.purchase && tx.status != 'REFUNDED')
        .map((tx) => tx.machineId)
        .toSet()
        .length;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.orange,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Hero header — expands, collapses to pinned navy bar, blurs on stretch
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              stretch: true,
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
              backgroundColor: Color.lerp(
                AppColors.offWhite,
                AppColors.originalCream,
                _collapseProgress,
              ),
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.blurBackground],
                background: SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _DashboardHeader(
                      onNotificationTap: widget.onNotificationTap,
                      onAvatarTap: widget.onAvatarTap,
                    ),
                  ),
                ),
              ),
            ),

            // Quick stats row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickStatCard(
                        icon: Icons.shopping_bag_rounded,
                        label: purchasesCount == 1 ? 'Purchase' : 'Purchases',
                        value: purchasesCount.toString(),
                        color: AppColors.success,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/transactions'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickStatCard(
                        icon: Icons.local_offer_rounded,
                        label: 'Spent',
                        value: 'EGP ${totalSpent.toStringAsFixed(2)}',
                        color: AppColors.orange,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/transactions'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickStatCard(
                        icon: Icons.storefront_rounded,
                        label: uniqueMachines == 1 ? 'Machine' : 'Machines',
                        value: uniqueMachines.toString(),
                        color: AppColors.navy,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/transactions'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // Transactions header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/transactions'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 5)),

            // Transaction list (limited to top 2 items)
            if (_transactions.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: AppColors.grey, fontSize: 14),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _TransactionTile(
                      tx: _transactions[index],
                      delay: Duration(milliseconds: 100 * index),
                    );
                  },
                  childCount:
                      _transactions.length > 2 ? 2 : _transactions.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 0)),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const _DashboardHeader({this.onNotificationTap, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final user = Provider.of<User>(context);
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
      child: Stack(
        children: [
          // Decorative orbs
          Positioned(
            top: -30,
            right: -20,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange.withOpacity(0.30),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -2,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange.withOpacity(0.20),
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back,',
                          style: TextStyle(
                            color: AppColors.navy.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.name} 👋',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Notification bell
                        GestureDetector(
                          onTap: onNotificationTap,
                          child: Stack(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.navy.withOpacity(0.1),
                                ),
                                child: const Icon(
                                  Icons.notifications_rounded,
                                  color: AppColors.navy,
                                  size: 22,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Avatar
                        GestureDetector(
                          onTap: onAvatarTap,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.orangeLight,
                                  AppColors.orangeDark,
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                user.avatarInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Balance card
                _BalanceCard(),

                const SizedBox(height: 20),

                // Ads section
                // _AdsCard(),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Balance Card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    return GlassCard(
      blur: 16,
      opacity: 0.14,
      borderColor: Colors.grey.withOpacity(0.15),
      shadows: [
        BoxShadow(
          color: Colors.white.withOpacity(0.25),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top row: label + chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'ivend',
                        style: const TextStyle(
                          fontFamily: AppFonts.outfit,
                          color: AppColors.orange,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      TextSpan(
                        text: ' by mobica',
                        style: const TextStyle(
                          fontFamily: AppFonts.montserrat,
                          color: AppColors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
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
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.rectangle,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: ' Wallet',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          color: AppColors.navy.withOpacity(0.7),
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.orange.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: AppColors.orangeLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Credits
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'EGP',
                  style: TextStyle(
                    color: AppColors.navyMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  user.walletBalance.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Divider
            // Divider(color: AppColors.navy.withOpacity(0.1), height: 1),

            // const SizedBox(height: 16),

            // Points row
            // Row(
            //   children: [
            //     Expanded(
            //       child: _WalletStat(
            //         icon: Icons.stars_rounded,
            //         label: 'Points Earned',
            //         value: user.totalPointsEarned.toString(),
            //         iconColor: AppColors.orangeLight,
            //       ),
            //     ),
            //     Container(
            //       width: 1,
            //       height: 36,
            //       color: AppColors.navy.withOpacity(0.1),
            //     ),
            //     Expanded(
            //       child: _WalletStat(
            //         icon: Icons.star_border_rounded,
            //         label: 'Points Used',
            //         value: user.totalPointsUsed.toString(),
            //         iconColor: AppColors.navyMuted,
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}

// ── Ads Card ──────────────────────────────────────────────────────────────────

// class _AdsCard extends StatefulWidget {
//   @override
//   State<_AdsCard> createState() => _AdsCardState();
// }

// class _AdsCardState extends State<_AdsCard>
//     with SingleTickerProviderStateMixin {
//   bool _claimed = false;
//   late final AnimationController _ctrl;
//   late final Animation<double> _scale;

// @override
// void initState() {
//   super.initState();
//   _ctrl = AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 300),
//     value: 1.0,
//   );
//   _scale = Tween<double>(
//     begin: 0.85,
//     end: 1.0,
//   ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
// }

// @override
// void dispose() {
//   _ctrl.dispose();
//   super.dispose();
// }

// void _onClaim() {
//   if (_claimed) return;
//   setState(() => _claimed = true);
//   _ctrl.reset();
//   _ctrl.forward();
// }

// @override
// Widget build(BuildContext context) {
//   return Container(
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(20),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.05),
//           blurRadius: 12,
//           offset: const Offset(0, 3),
//         ),
//       ],
//     ),
//     child: AnimatedContainer(
//       duration: const Duration(milliseconds: 350),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: _claimed
//               ? [
//                   AppColors.success.withOpacity(0.10),
//                   AppColors.success.withOpacity(0.04),
//                 ]
//               : [
//                   AppColors.orange.withOpacity(0.12),
//                   AppColors.orangeLight.withOpacity(0.06),
//                 ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: _claimed
//               ? AppColors.success.withOpacity(0.25)
//               : AppColors.orange.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Container(
//               width: 48,
//               height: 48,
//               decoration: BoxDecoration(
//                 color: _claimed
//                     ? AppColors.success.withOpacity(0.12)
//                     : AppColors.orange.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Icon(
//                 _claimed
//                     ? Icons.check_circle_rounded
//                     : Icons.campaign_rounded,
//                 color: _claimed ? AppColors.success : AppColors.orange,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     _claimed ? 'Offer Claimed!' : 'Special Offer!',
//                     style: TextStyle(
//                       color: _claimed ? AppColors.success : AppColors.navy,
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     _claimed
//                         ? '20% extra points applied to your account'
//                         : 'Get 20% extra points on every purchase',
//                     style: TextStyle(
//                       color: (_claimed ? AppColors.success : AppColors.navy)
//                           .withOpacity(0.6),
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             GestureDetector(
//               onTap: _onClaim,
//               child: ScaleTransition(
//                 scale: _scale,
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 350),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: _claimed ? AppColors.success : AppColors.orange,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if (_claimed) ...[
//                         const Icon(
//                           Icons.check_rounded,
//                           color: Colors.white,
//                           size: 12,
//                         ),
//                         const SizedBox(width: 4),
//                       ],
//                       Text(
//                         _claimed ? 'Claimed' : 'Claim',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }
// }

class _WalletStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _WalletStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.navy.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Stat Card ───────────────────────────────────────────────────────────

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onPressed;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: value.startsWith('EGP ')
                  ? RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'EGP ',
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: value.substring(4),
                            style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatefulWidget {
  final TransactionModel tx;
  final Duration delay;

  const _TransactionTile({required this.tx, required this.delay});

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _slide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _typeColor {
    if (widget.tx.status.isNotEmpty) {
      switch (widget.tx.status) {
        case 'COMPLETED':
          return AppColors.success;
        case 'FAILED':
          return AppColors.error;
        case 'REFUNDED':
          return AppColors.warning;
        case 'PAID':
          return AppColors.orange;
        case 'CREDIT':
          return AppColors.success;
        default:
          return AppColors.grey;
      }
    }
    switch (widget.tx.type) {
      case TransactionType.purchase:
        return AppColors.navy;
      case TransactionType.pointsEarned:
        return AppColors.success;
      case TransactionType.pointsRedeemed:
        return AppColors.orange;
      case TransactionType.topUp:
        return AppColors.success;
    }
  }

  String get _amountText {
    if (widget.tx.type == TransactionType.topUp) {
      return '+EGP ${widget.tx.amount.toStringAsFixed(2)}';
    }
    return '-EGP ${widget.tx.amount.abs().toStringAsFixed(2)}';
  }

  String get _timeText {
    final now = DateTime.now();
    final diff = now.difference(widget.tx.date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/transactions'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.tx.icon, color: _typeColor, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tx.title,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.tx.subtitle,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Amount & time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _amountText,
                        style: TextStyle(
                          color: _typeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _timeText,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
