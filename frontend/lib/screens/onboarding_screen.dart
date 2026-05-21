import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';


class _OnboardPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color accent;
  final List<Color> gradientColors;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.accent,
    required this.gradientColors,
  });
}

const _pages = [
  _OnboardPage(
    title: 'TAP\nYour Selection',
    subtitle:
        'Browse products, tap to select, and confirm your choice with ease.',
    icon: Icons.touch_app_rounded,
    iconBg: AppColors.orange,
    accent: AppColors.orange,
    gradientColors: [AppColors.originalCream, AppColors.originalCreamLight],
  ),
  _OnboardPage(
    title: 'VEND\nInstantly',
    subtitle:
        'Watch your product dispense from the machine with our vending process.',
    icon: Icons.local_grocery_store_rounded,
    iconBg: AppColors.orange,
    accent: AppColors.orangeLight,
    gradientColors: [AppColors.originalCreamLight, AppColors.originalCreamMid],
  ),
  _OnboardPage(
    title: 'GO\nEnjoy Your Snack',
    subtitle:
        'Grab your product and go - the perfect solution for quick, convenient snacking.',
    icon: Icons.directions_walk_rounded,
    iconBg: AppColors.orange,
    accent: AppColors.orange,
    gradientColors: [AppColors.originalCreamMid, AppColors.originalCream],
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  late AnimationController _iconCtrl;
  late Animation<double> _iconBounce;

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconBounce = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await UserService.setNotFirstTime();
      if (mounted) Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  void _animateIcon() {
    _iconCtrl.reset();
    _iconCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final page = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: TextButton(
                    onPressed: () async {
                      await UserService.setNotFirstTime();
                      if (mounted) Navigator.pushReplacementNamed(context, '/signin');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.navy.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _animateIcon();
                  },
                  itemBuilder: (context, index) {
                    final p = _pages[index];
                    return _OnboardPageView(
                      page: p,
                      size: size,
                      iconCtrl: _iconCtrl,
                      iconBounce: _iconBounce,
                      isActive: index == _currentPage,
                    );
                  },
                ),
              ),

              // Dots + button
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? AppColors.orange
                                : AppColors.navy.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 36),

                    // Next / Get Started button
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.orangeLight,
                              AppColors.orange,
                              AppColors.orangeDark,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }
}

class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  final Size size;
  final AnimationController iconCtrl;
  final Animation<double> iconBounce;
  final bool isActive;

  const _OnboardPageView({
    required this.page,
    required this.size,
    required this.iconCtrl,
    required this.iconBounce,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with rings
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange.withOpacity(0.07),
                  border: Border.all(
                    color: AppColors.orange.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              // Mid ring
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.orange.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              // Icon badge
              AnimatedBuilder(
                animation: iconBounce,
                builder: (context, child) => Transform.scale(
                  scale: isActive ? iconBounce.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.orangeLight, AppColors.orangeDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(page.icon, color: Colors.white, size: 52),
                ),
              ),
            ],
          ),

          const SizedBox(height: 52),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy.withOpacity(0.65),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

