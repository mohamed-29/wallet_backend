import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

// enum _Filter { all, purchases, points, topUp }
enum _Filter { all, purchases, topUp }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  _Filter _activeFilter = _Filter.all;
  late ScrollController _scrollController;
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const expandedHeight = 300.0;
    const fadeStart = 150.0; // start fading from the halfway point of collapse
    final pixels =
        _scrollController.hasClients ? _scrollController.position.pixels : 0.0;
    final progress =
        ((pixels - fadeStart) / (expandedHeight - fadeStart)).clamp(0.0, 1.0);
    if (progress != _appBarOpacity) {
      setState(() => _appBarOpacity = progress);
    }
  }

  // ── Filtered list ──────────────────────────────────────────────────────────
  List<TransactionModel> get _filtered {
    switch (_activeFilter) {
      case _Filter.all:
        return mockTransactions;
      case _Filter.purchases:
        return mockTransactions
            .where((t) => t.type == TransactionType.purchase)
            .toList();
      // case _Filter.points:
      //   return mockTransactions
      //       .where(
      //         (t) =>
      //             t.type == TransactionType.pointsEarned ||
      //             t.type == TransactionType.pointsRedeemed,
      //       )
      //       .toList();
      case _Filter.topUp:
        return mockTransactions
            .where((t) =>
                t.type == TransactionType.topUp && t.status != 'REFUNDED')
            .toList();
    }
  }

  // ── Group by readable date label ───────────────────────────────────────────
  Map<String, List<TransactionModel>> get _grouped {
    final result = <String, List<TransactionModel>>{};
    for (final tx in _filtered) {
      result.putIfAbsent(_label(tx.date), () => []).add(tx);
    }
    return result;
  }

  String _label(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[date.weekday - 1];
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ── Summary numbers ────────────────────────────────────────────────────────
  double get _totalSpent => mockTransactions
      .where(
          (t) => t.type == TransactionType.purchase && t.status != 'REFUNDED')
      .fold(0.0, (s, t) => s + t.amount.abs());

  double get _totalPtsEarned => currentUser.totalPointsEarned;

  double get _totalPtsUsed => currentUser.totalPointsUsed;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final groups = grouped.entries.toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Gradient hero header ────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: Color.lerp(
                  AppColors.offWhite,
                  AppColors.originalCreamMid,
                  _appBarOpacity,
                ),
                surfaceTintColor: Colors.transparent,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.navy,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Transactions',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.navy.withOpacity(0.7),
                    ),
                    onPressed: () {},
                    tooltip: 'Export',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.blurBackground],
                  background: _HeroHeader(
                    totalSpent: _totalSpent,
                    totalPtsEarned: _totalPtsEarned,
                    totalPtsUsed: _totalPtsUsed,
                    totalCount: mockTransactions.length,
                    purchasesCount: mockTransactions
                        .where((t) =>
                            t.type == TransactionType.purchase &&
                            t.status != 'REFUNDED')
                        .length,
                    topUpTotal: mockTransactions
                        .where((t) =>
                            t.type == TransactionType.topUp &&
                            t.status != 'REFUNDED')
                        .fold(0.0, (s, t) => s + t.amount),
                  ),
                ),
              ),

              // ── Sticky filter chips ─────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterDelegate(
                  active: _activeFilter,
                  onChanged: (f) => setState(() => _activeFilter = f),
                ),
              ),

              // ── Empty state ─────────────────────────────────────────────────
              if (groups.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: AppColors.beige,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No transactions here',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              // ── Date-grouped list ───────────────────────────────────────────
              else
                for (final entry in groups) ...[
                  SliverToBoxAdapter(child: _SectionHeader(label: entry.key)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TxTile(
                        tx: entry.value[i],
                        delay: Duration(milliseconds: 40 * i),
                      ),
                      childCount: entry.value.length,
                    ),
                  ),
                ],

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero header (lives inside SliverAppBar flexible space)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final double totalSpent;
  final double totalPtsEarned;
  final double totalPtsUsed;
  final int totalCount;
  final int purchasesCount;
  final double topUpTotal;

  const _HeroHeader({
    required this.totalSpent,
    required this.totalPtsEarned,
    required this.totalPtsUsed,
    required this.totalCount,
    required this.purchasesCount,
    required this.topUpTotal,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Stack(
        children: [
          // Decorative orange blobs
          Positioned(
            top: -30,
            right: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange.withOpacity(0.30),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange.withOpacity(0.20),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(24, top + 64, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.orange.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: AppColors.orange.withOpacity(0.9),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'This Month',
                        style: TextStyle(
                          color: AppColors.orange.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Total spent label
                Text(
                  'Total Spent',
                  style: TextStyle(
                    color: AppColors.navy.withOpacity(0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),

                // Big number
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'EGP ',
                        style: TextStyle(
                          color: AppColors.navy.withOpacity(0.6),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: totalSpent.toStringAsFixed(2),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    _QuickStat(
                      label: 'Transactions',
                      value: '$totalCount',
                      icon: Icons.receipt_rounded,
                      accent: null,
                    ),
                    const SizedBox(width: 10),
                    _QuickStat(
                      label: purchasesCount == 1 ? 'Purchase' : 'Purchases',
                      value: '$purchasesCount',
                      icon: Icons.shopping_bag_rounded,
                      accent: AppColors.orange,
                    ),
                    const SizedBox(width: 10),
                    _QuickStat(
                      label: 'Top-ups',
                      value: 'EGP ${topUpTotal.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet_rounded,
                      accent: AppColors.success,
                    ),
                  ],
                ),

                // // 3 quick-stat boxes
                // Row(
                //   children: [
                //     _QuickStat(
                //       label: 'Transactions',
                //       value: '$totalCount',
                //       icon: Icons.receipt_rounded,
                //       accent: null,
                //     ),
                //     const SizedBox(width: 10),
                //     _QuickStat(
                //       label: 'Pts Earned',
                //       value: '+$totalPtsEarned',
                //       icon: Icons.stars_rounded,
                //       accent: AppColors.success,
                //     ),
                //     const SizedBox(width: 10),
                //     _QuickStat(
                //       label: 'Pts Used',
                //       value: '-$totalPtsUsed',
                //       icon: Icons.redeem_rounded,
                //       accent: AppColors.orange,
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? accent; // null = white

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = accent ?? AppColors.navy;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.navy.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.navy.withOpacity(0.4), size: 15),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: value.startsWith('EGP ')
                  ? RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'EGP ',
                            style: TextStyle(
                              color: valueColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: value.substring(4),
                            style: TextStyle(
                              color: valueColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: 0.5),
                  fontSize: 9.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// Sticky filter chip row
// ─────────────────────────────────────────────────────────────────────────────

class _FilterDelegate extends SliverPersistentHeaderDelegate {
  final _Filter active;
  final ValueChanged<_Filter> onChanged;

  const _FilterDelegate({required this.active, required this.onChanged});

  static const _labels = {
    _Filter.all: 'All',
    _Filter.purchases: 'Purchases',
    // _Filter.points: 'Points',
    _Filter.topUp: 'Top-ups',
  };

  @override
  double get minExtent => 58;
  @override
  double get maxExtent => 58;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.offWhite,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _Filter.values.map((f) {
                  final isActive = f == active;
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                      top: 10,
                      bottom: 10,
                    ),
                    child: GestureDetector(
                      onTap: () => onChanged(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.orange : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isActive ? AppColors.orange : AppColors.beige,
                            width: 1.5,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.orange.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _labels[f]!,
                          style: TextStyle(
                            color: isActive ? Colors.white : AppColors.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // thin divider
          Container(height: 1, color: AppColors.beige.withOpacity(0.6)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterDelegate old) => old.active != active;
}

// ─────────────────────────────────────────────────────────────────────────────
// Date section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.beigeMid,
                    AppColors.beige.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction tile
// ─────────────────────────────────────────────────────────────────────────────

class _TxTile extends StatefulWidget {
  final TransactionModel tx;
  final Duration delay;

  const _TxTile({required this.tx, required this.delay});

  @override
  State<_TxTile> createState() => _TxTileState();
}

class _TxTileState extends State<_TxTile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
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

  Color get _accent {
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
      case TransactionType.drawdown:
        return AppColors.error;
    }
  }

  String get _amountText {
    if (widget.tx.type == TransactionType.topUp) {
      return '+EGP ${widget.tx.amount.toStringAsFixed(2)}';
    } else if (widget.tx.type == TransactionType.drawdown) {
      return '-EGP ${widget.tx.amount.abs().toStringAsFixed(2)}';
    }
    return '-EGP ${widget.tx.amount.abs().toStringAsFixed(2)}';
  }

  String get _timeText {
    final now = DateTime.now();
    final diff = now.difference(widget.tx.date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${widget.tx.date.day} ${months[widget.tx.date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left accent bar ───────────────────────────────────
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_accent, _accent.withOpacity(0.5)],
                        ),
                      ),
                    ),

                    // ── Content ───────────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon badge
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                widget.tx.icon,
                                color: _accent,
                                size: 21,
                              ),
                            ),

                            const SizedBox(width: 13),

                            // Title + subtitle + points badge
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.tx.title,
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (widget.tx.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.tx.subtitle,
                                      style: const TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 11.5,
                                        height: 1.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  // Points earned pill on purchases
                                  if (widget.tx.type ==
                                          TransactionType.purchase &&
                                      widget.tx.pointsDelta > 0) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.orange.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.stars_rounded,
                                            size: 11,
                                            color: AppColors.orange,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '+${widget.tx.pointsDelta} pts',
                                            style: const TextStyle(
                                              color: AppColors.orange,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Amount + time + machine tag
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _amountText,
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _timeText,
                                  style: TextStyle(
                                    color: AppColors.grey.withOpacity(
                                      0.75,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                                if (widget.tx.machineId.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.originalCream.withOpacity(
                                        0.06,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      widget.tx.machineId,
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
