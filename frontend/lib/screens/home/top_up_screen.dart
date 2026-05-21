import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  double _collapseProgress = 0.0;
  static const double _expandedHeight = 180.0;
  static const double _fadeStart = 90.0;

  int? _selectedPreset;
  int _selectedPayment = 0;
  final _customCtrl = TextEditingController();
  bool _useCustom = false;

  static const _presets = [10, 25, 50, 100, 200];
  static const _methods = [
    _PayMethod(icon: Icons.credit_card_rounded, label: 'Card'),
    _PayMethod(icon: Icons.phone_iphone_rounded, label: 'Apple Pay'),
    _PayMethod(icon: Icons.g_mobiledata_rounded, label: 'Google Pay'),
  ];

  @override
  void initState() {
    super.initState();
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
    _scrollCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  double get _amount {
    if (_useCustom) return double.tryParse(_customCtrl.text) ?? 0;
    if (_selectedPreset != null) return _presets[_selectedPreset!].toDouble();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 95,
            pinned: true,
            stretch: true,
            toolbarHeight: 0,
            automaticallyImplyLeading: false,
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
                    child: Stack(
                      children: [
                        Positioned(
                          top: -20,
                          right: -30,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 20,
                              sigmaY: 20,
                            ),
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.orange.withOpacity(0.08),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(24, top + 16, 24, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.navy.withOpacity(
                                           0.08,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: AppColors.navy,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Top Up Wallet',
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Current balance: EGP ${Provider.of<User>(context).walletBalance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: AppColors.navy.withOpacity(
                                             0.55,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount section
                  const Text(
                    'SELECT AMOUNT',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Preset pills
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_presets.length, (i) {
                      final selected = !_useCustom && _selectedPreset == i;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedPreset = i;
                          _useCustom = false;
                          _customCtrl.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.orange : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.orange
                                  : AppColors.beige,
                              width: 1.5,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.orange.withOpacity(
                                         0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                         0.04,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Text(
                            'EGP ${_presets[i]}',
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Custom amount
                  GestureDetector(
                    onTap: () => setState(() {
                      _useCustom = true;
                      _selectedPreset = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        // border: Border.all(
                        //   color: _useCustom
                        //       ? AppColors.orange
                        //       : AppColors.beige,
                        //   width: 1.5,
                        // ),
                        boxShadow: [
                          BoxShadow(
                            color: _useCustom
                                ? AppColors.orange.withOpacity(0.1)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'EGP',
                              style: TextStyle(
                                color: _useCustom
                                    ? AppColors.orange
                                    : AppColors.grey,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: AppColors.beige,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _customCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Other amount',
                                hintStyle: TextStyle(
                                  color: AppColors.grey.withOpacity(0.6),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                suffixIcon: _customCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.check_rounded,
                                          size: 20,
                                          color: AppColors.orange,
                                        ),
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setState(() {
                                _useCustom = true;
                                _selectedPreset = null;
                              }),
                              onSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Payment method
                  const Text(
                    'PAYMENT METHOD',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
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
                      children: List.generate(_methods.length, (i) {
                        final selected = _selectedPayment == i;
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _selectedPayment = i),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.orange.withOpacity(
                                                 0.1,
                                              )
                                            : AppColors.lightGrey,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _methods[i].icon,
                                        color: selected
                                            ? AppColors.orange
                                            : AppColors.grey,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        _methods[i].label,
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 14,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.orange
                                              : AppColors.beige,
                                          width: selected ? 6 : 2,
                                        ),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (i < _methods.length - 1)
                              Divider(
                                height: 1,
                                indent: 76,
                                endIndent: 20,
                                color: AppColors.lightGrey,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Summary
                  if (_amount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.originalCream.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.originalCream.withOpacity(
                             0.08,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'You will add',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'EGP ${_amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedOpacity(
                      opacity: _amount > 0 ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 220),
                      child: GestureDetector(
                        onTap: _amount > 0
                            ? () {
                                HapticFeedback.mediumImpact();
                                _showSuccess(context);
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.orangeLight,
                                AppColors.orange,
                                AppColors.orangeDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _amount > 0
                                    ? 'Pay EGP ${_amount.toStringAsFixed(2)}'
                                    : 'Select an amount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: 13,
                          color: AppColors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Secured by 256-bit encryption',
                          style: TextStyle(
                            color: AppColors.grey.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context) {
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'EGP ${_amount.toStringAsFixed(2)} Added!',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your new balance will be EGP ${(Provider.of<User>(context, listen: false).walletBalance + _amount).toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Update the user's wallet balance
                  final user = Provider.of<User>(context, listen: false);
                  user.addTopUp(_amount);

                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PayMethod {
  final IconData icon;
  final String label;
  const _PayMethod({required this.icon, required this.label});
}

