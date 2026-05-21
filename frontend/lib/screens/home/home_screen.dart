import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';
import 'qr_screen.dart';
import 'locations_screen.dart';
import 'help_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _fabScale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    _fabCtrl.reset();
    _fabCtrl.forward();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TickerMode(
            enabled: _currentIndex == 0,
            child: DashboardScreen(
              onNotificationTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              onAvatarTap: () => _onTabTap(4),
            ),
          ),
          TickerMode(
            enabled: _currentIndex == 1,
            child: QrScreen(isActive: _currentIndex == 1),
          ),
          TickerMode(
            enabled: _currentIndex == 2,
            child: const LocationsScreen(),
          ),
          TickerMode(enabled: _currentIndex == 3, child: const HelpScreen()),
          TickerMode(enabled: _currentIndex == 4, child: const ProfileScreen()),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTabTap(0),
                ),
                _NavItem(
                  icon: Icons.location_on_rounded,
                  label: 'Locations',
                  isActive: _currentIndex == 2,
                  onTap: () => _onTabTap(2),
                ),
                // QR center tab — elevated pill
                GestureDetector(
                  onTap: () => _onTabTap(1),
                  child: AnimatedBuilder(
                    animation: _fabScale,
                    builder: (context, child) => Transform.scale(
                      scale: _currentIndex == 1 ? _fabScale.value : 1.0,
                      child: child,
                    ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _currentIndex == 1
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.orangeLight,
                                  AppColors.orange,
                                  AppColors.orangeDark,
                                ],
                              )
                            : const LinearGradient(
                                colors: [
                                  AppColors.originalCream,
                                  AppColors.originalCreamLight,
                                ],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_currentIndex == 1
                                        ? AppColors.orange
                                        : AppColors.originalCream)
                                    .withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_rounded,
                        color: AppColors.navy,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help',
                  isActive: _currentIndex == 3,
                  onTap: () => _onTabTap(3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => _onTabTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.orange.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? AppColors.orange : AppColors.grey,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.orange : AppColors.grey,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

