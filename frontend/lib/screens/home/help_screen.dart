import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  double _collapseProgress = 0.0;
  static const double _expandedHeight = 170.0;
  static const double _fadeStart = 85.0;
  int? _expandedIndex;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;

  final _faqs = const [
    _FaqItem(
      question: 'How do I use my QR code at the machine?',
      answer:
          'On any ivend machine, tap the "Mobile App" button on the touchscreen. Hold your ivend app scanner up to the QR code. Once scanned, your wallet and points will be loaded and you can select your payment option.',
      icon: Icons.qr_code_rounded,
    ),
    // _FaqItem(
    //   question: 'How do I earn points?',
    //   answer:
    //       'You earn 1 ivend Points for every EGP 1 spent. Points are automatically added after each successful purchase. Bonus points are available during promotions.',
    //   icon: Icons.stars_rounded,
    // ),
    // _FaqItem(
    //   question: 'How do I redeem my points?',
    //   answer:
    //       'At checkout on any ivend machine, select "Redeem Points" before confirming your purchase. Points are applied as a discount — 100 points = EGP 1.',
    //   icon: Icons.redeem_rounded,
    // ),
    _FaqItem(
      question: 'How do I top up my wallet?',
      answer:
          'Go to Profile > Wallet > Top Up. You can add funds using credit/debit card, Apple Pay, or Google Pay. Minimum top-up is EGP 10.',
      icon: Icons.account_balance_wallet_rounded,
    ),
    _FaqItem(
      question: 'My purchase didn\'t go through but I was charged',
      answer:
          'Payments are automatically reversed within 1 business day if a product wasn\'t dispensed. If you haven\'t received a refund within 24 hours, please contact support with your transaction ID.',
      icon: Icons.payment_rounded,
    ),
    _FaqItem(
      question: 'Can I use ivend in multiple countries?',
      answer:
          'ivend is currently available across Egypt. We\'re expanding to Saudi Arabia in 2026. Stay tuned for announcements!',
      icon: Icons.public_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn));
    _entryCtrl.forward();
    _scrollCtrl.addListener(_onScroll);
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
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // Helper method to launch WhatsApp
  Future<void> _launchWhatsApp() async {
    final phoneNumber = '+201066664607';
    final url = 'https://wa.me/$phoneNumber';

    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      // Fallback to tel: scheme if WhatsApp is not available
      final telUrl = 'tel:$phoneNumber';
      await launchUrl(Uri.parse(telUrl));
    }
  }

  // Helper method to launch email
  Future<void> _launchEmail() async {
    final email = 'IVend@mobica.net';
    final subject = 'ivend Support Request';
    final url = 'mailto:$email?subject=${Uri.encodeComponent(subject)}';

    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      // Handle error if email app is not available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open email app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // Hero header — expands, collapses to pinned navy bar, blurs on stretch
          SliverAppBar(
            expandedHeight: 170,
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
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            // title: const Text(
            //   'Help & Support',
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontSize: 17,
            //     fontWeight: FontWeight.w700,
            //   ),
            // ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.blurBackground],
              background: Builder(
                builder: (ctx) {
                  final top = MediaQuery.of(ctx).padding.top;
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
                      padding: EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.of(context).padding.top + 20,
                        20,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.info,
                                  color: AppColors.orange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Help & Support',
                                    style: TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'We\'re here for you',
                                    style: TextStyle(
                                      color: AppColors.navyMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Search bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(15),
                              // border: Border.all(
                              //   color: AppColors.navy.withOpacity(0.15),
                              // ),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search FAQs...',
                                hintStyle: TextStyle(
                                  color: AppColors.navy.withOpacity(0.45),
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: AppColors.navy.withOpacity(0.5),
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                filled: false,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Contact cards
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _entryFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    // Expanded(
                    //   child: _ContactCard(
                    //     icon: Icons.chat_bubble_rounded,
                    //     label: 'Live Chat',
                    //     sublabel: 'Online now',
                    //     color: AppColors.success,
                    //     onTap: () {},
                    //   ),
                    // ),
                    // const SizedBox(width: 12),
                    // Expanded(
                    //   child: _ContactCard(
                    //     icon: Icons.phone_rounded,
                    //     label: 'Whatsapp',
                    //     sublabel: '+201066664607',
                    //     color: const Color.fromARGB(255, 56, 162, 21),
                    //     onTap: _launchWhatsApp,
                    //   ),
                    // ),
                    // const SizedBox(width: 12),
                    Expanded(
                      child: _ContactCard(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        sublabel: 'IVend@mobica.net',
                        color: AppColors.orange,
                        onTap: _launchEmail,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // FAQ header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_filteredFaqs.length}',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FAQ list
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final faq = _filteredFaqs[index];
              final isExpanded = _expandedIndex == index;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _FaqTile(
                  faq: faq,
                  isExpanded: isExpanded,
                  onTap: () {
                    setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    });
                  },
                ),
              );
            }, childCount: _filteredFaqs.length),
          ),

          // Bottom spacer
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  List<_FaqItem> get _filteredFaqs {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _faqs;
    return _faqs
        .where(
          (f) =>
              f.question.toLowerCase().contains(q) ||
              f.answer.toLowerCase().contains(q),
        )
        .toList();
  }
}

class _FaqItem {
  final String question;
  final String answer;
  final IconData icon;
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.icon,
  });
}

class _FaqTile extends StatefulWidget {
  final _FaqItem faq;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FaqTile({
    required this.faq,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _pressScale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (context, child) =>
            Transform.scale(scale: _pressScale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isExpanded
                  ? AppColors.orange.withOpacity(0.35)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isExpanded
                    ? AppColors.orange.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: widget.isExpanded ? 20 : 8,
                offset: const Offset(0, 4),
                spreadRadius: widget.isExpanded ? 1 : 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon badge — color shifts, no spin
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.isExpanded
                            ? AppColors.orange.withOpacity(0.12)
                            : AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.faq.icon,
                        color: widget.isExpanded
                            ? AppColors.orange
                            : AppColors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 14,
                          fontWeight: widget.isExpanded
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: 1.4,
                        ),
                        child: Text(widget.faq.question),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Chevron rotates 180°
                    AnimatedRotation(
                      turns: widget.isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.isExpanded
                            ? AppColors.orange
                            : AppColors.grey,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                // Answer slides open smoothly
                AnimatedSize(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topLeft,
                  child: widget.isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 14, left: 54),
                          child: AnimatedOpacity(
                            opacity: widget.isExpanded ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeIn,
                            child: Text(
                              widget.faq.answer,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13.5,
                                height: 1.7,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(color: AppColors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
