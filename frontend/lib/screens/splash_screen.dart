import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _textCtrl;
  late final AnimationController _exitCtrl;
  late final AnimationController _elevatorCtrl;
  late final AnimationController _doorCtrl;

  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;

  // Vending machine state
  double _elevatorY = 67.0;
  int _selectedIdx = -1;
  bool _productOnElevator = false;
  bool _productInTray = false;
  bool _cycling = false;

  static const _products = [
    _Product(x: 16, y: 22, color: Color(0xFFF97300)),
    _Product(x: 29, y: 22, color: Color(0xFF3B82F6)),
    _Product(x: 42, y: 22, color: Color(0xFF10B981)),
    _Product(x: 16, y: 39, color: Color(0xFFEF4444)),
    _Product(x: 29, y: 39, color: Color(0xFF8B5CF6)),
    _Product(x: 42, y: 39, color: Color(0xFFF59E0B)),
  ];

  @override
  void initState() {
    super.initState();

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _elevatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _exitScale = Tween<double>(
      begin: 1.0,
      end: 20.0,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic));
    _exitFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _exitCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _runSequence();
  }

  // Smoothly animate the elevator to [targetY] in SVG space.
  Future<void> _moveElevatorTo(double targetY) async {
    final fromY = _elevatorY;
    final anim = Tween<double>(
      begin: fromY,
      end: targetY,
    ).animate(CurvedAnimation(parent: _elevatorCtrl, curve: Curves.easeInOut));
    void tick() {
      if (mounted) setState(() => _elevatorY = anim.value);
    }

    _elevatorCtrl.reset();
    _elevatorCtrl.addListener(tick);
    await _elevatorCtrl.forward();
    _elevatorCtrl.removeListener(tick);
    if (mounted) setState(() => _elevatorY = targetY);
  }

  Future<void> _runSequence() async {
    // Kick off the looping vending animation immediately.
    _cycling = true;
    _runVendingCycle();

    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();

    // Total splash duration ≈ 4.5 s
    await Future.delayed(const Duration(milliseconds: 3700));
    _cycling = false;
    _exitCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      if (UserService.isFirstTimeFlag) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else if (UserService.token != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    }
  }

  Future<void> _runVendingCycle() async {
    if (!mounted || !_cycling) return;

    final idx = math.Random().nextInt(_products.length);
    final product = _products[idx];
    final platformTargetY = product.y + 11.0; // platform just below product

    // 1. Reveal elevator at bottom, pick product
    setState(() {
      _selectedIdx = idx;
      _productOnElevator = false;
      _productInTray = false;
    });

    // 2. Rise to shelf
    await _moveElevatorTo(platformTargetY);
    if (!mounted || !_cycling) return;

    // 3. Grab product (brief pause)
    await Future.delayed(const Duration(milliseconds: 380));
    if (!mounted || !_cycling) return;
    setState(() => _productOnElevator = true);

    // 4. Lower to POS bottom (not all the way to tray)
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted || !_cycling) return;
    await _moveElevatorTo(65.0);
    if (!mounted || !_cycling) return;

    // 5. Eject into tray, open door
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted || !_cycling) return;
    setState(() {
      _productOnElevator = false;
      _productInTray = true;
    });
    _doorCtrl.reset();
    await _doorCtrl.forward();
    if (!mounted || !_cycling) return;

    // 6. Hold so user sees the product
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted || !_cycling) return;

    // 7. Reset
    _doorCtrl.reset();
    setState(() {
      _productInTray = false;
      _selectedIdx = -1;
      _elevatorY = 67.0;
    });
    await Future.delayed(const Duration(milliseconds: 280));

    _runVendingCycle();
  }

  @override
  void dispose() {
    _cycling = false;
    _textCtrl.dispose();
    _exitCtrl.dispose();
    _elevatorCtrl.dispose();
    _doorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.originalCream,
      body: AnimatedBuilder(
        animation: Listenable.merge([_textCtrl, _exitCtrl, _doorCtrl]),
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.originalCream,
                  AppColors.originalCreamLight,
                  AppColors.originalCreamMid,
                ],
                stops: [0.1, 0.6, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Background accent blobs
                Positioned(
                  top: -size.width * 0.3,
                  right: -size.width * 0.2,
                  child: _Blob(size: size.width * 0.8, opacity: 0.07),
                ),
                Positioned(
                  bottom: -size.width * 0.4,
                  left: -size.width * 0.2,
                  child: _Blob(size: size.width * 0.9, opacity: 0.04),
                ),

                // Main content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Vending Machine ──────────────────────────────
                      SizedBox(
                        width: 192,
                        height: 240,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _VendingMachinePainter(
                              elevatorY: _elevatorY,
                              selectedIdx: _selectedIdx,
                              productOnElevator: _productOnElevator,
                              productInTray: _productInTray,
                              doorOpenAmount: _doorCtrl.value,
                              products: _products,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── Brand text ───────────────────────────────────
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textOpacity,
                          child: SizedBox(
                            width: size.width,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ivend + tap.vend.go row
                                IntrinsicHeight(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // ivend
                                          const Text(
                                            'ivend',
                                            style: TextStyle(
                                              fontFamily: AppFonts.outfit,
                                              color: AppColors.orange,
                                              fontSize: 100,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -2,
                                              height: 1,
                                            ),
                                          ),
                                          // by — indented slightly left
                                          const Padding(
                                            padding: EdgeInsets.only(left: 20),
                                            child: Text(
                                              'by',
                                              style: TextStyle(
                                                fontFamily: AppFonts.montserrat,
                                                color: AppColors.orange,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0,
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 6),
                                      // tap.vend.go — vertical, right side
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 13,
                                          ),
                                          child: RotatedBox(
                                            quarterTurns: 1,
                                            child: Text(
                                              'tap.vend.go',
                                              style: const TextStyle(
                                                fontFamily: AppFonts.montserrat,
                                                color: AppColors.orange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // mobica — centered on screen
                                Center(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'mobica',
                                          style: TextStyle(
                                            fontFamily: AppFonts.montserrat,
                                            color: AppColors.orange,
                                            fontSize: 46,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1.5,
                                            height: 1,
                                          ),
                                        ),
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment
                                              .aboveBaseline,
                                          baseline: TextBaseline.alphabetic,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 3,
                                            ),
                                            child: Container(
                                              width: 9,
                                              height: 9,
                                              color: AppColors.orange,
                                            ),
                                          ),
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
                    ],
                  ),
                ), // Bottom tagline
                // Exit transition: orange circle expands
                if (_exitCtrl.value > 0)
                  Center(
                    child: Transform.scale(
                      scale: _exitScale.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.orange.withOpacity(
                             _exitFade.value,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vending Machine CustomPainter
// SVG viewBox 0 0 80 100; scaled to widget size.
// ─────────────────────────────────────────────────────────────────────────────

class _Product {
  final double x, y;
  final Color color;
  const _Product({required this.x, required this.y, required this.color});
}

class _VendingMachinePainter extends CustomPainter {
  final double elevatorY;
  final int selectedIdx;
  final bool productOnElevator;
  final bool productInTray;
  final double doorOpenAmount; // 0=closed, 1=open
  final List<_Product> products;

  const _VendingMachinePainter({
    required this.elevatorY,
    required this.selectedIdx,
    required this.productOnElevator,
    required this.productInTray,
    required this.doorOpenAmount,
    required this.products,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 80.0, size.height / 100.0);
    _paintMachine(canvas);
    canvas.restore();
  }

  void _paintMachine(Canvas canvas) {
    final p = Paint()..isAntiAlias = true;

    // ── Drop shadow ──────────────────────────────────────────────────────────
    p.color = Colors.black.withOpacity(0.18);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    _rr(canvas, p, 5, 8, 70, 90, 7);
    p.maskFilter = null;

    // ── Machine body ─────────────────────────────────────────────────────────
    p.color = Colors.white;
    _rr(canvas, p, 5, 5, 70, 90, 7);

    p.color = const Color(0xFF1E293B);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1.8;
    _rr(canvas, p, 5, 5, 70, 90, 7);
    p.style = PaintingStyle.fill;

    p.color = const Color(0xFFF1F5F9);
    _rr(canvas, p, 7, 7, 66, 86, 6);

    // ── Glass display area ───────────────────────────────────────────────────
    p.color = const Color(0xFFD6E8F7);
    _rr(canvas, p, 12, 15, 42, 52, 2);
    p.color = const Color(0xFFAEC6DE);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 0.8;
    _rr(canvas, p, 12, 15, 42, 52, 2);
    p.style = PaintingStyle.fill;

    // Glass inner reflection (left strip)
    p.color = Colors.white.withOpacity(0.12);
    _rr(canvas, p, 12, 15, 18, 52, 0);

    // ── Shelves ──────────────────────────────────────────────────────────────
    p.color = const Color(0xFF8BA6C0);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1.5;
    canvas.drawLine(const Offset(12, 35), const Offset(54, 35), p);
    canvas.drawLine(const Offset(12, 52), const Offset(54, 52), p);
    p.style = PaintingStyle.fill;

    // ── Shelf products ───────────────────────────────────────────────────────
    for (int i = 0; i < products.length; i++) {
      final prod = products[i];
      final taken = i == selectedIdx && (productOnElevator || productInTray);
      if (taken) continue;
      _drawProduct(canvas, p, prod.x, prod.y, prod.color);
    }

    // ── Rail guides (thin vertical lines inside glass) - STATIC
    p.color = const Color(0xFF64748B).withOpacity(0.5);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 0.6;
    canvas.drawLine(const Offset(14.5, 15), const Offset(14.5, 67), p);
    canvas.drawLine(const Offset(51.5, 15), const Offset(51.5, 67), p);
    p.style = PaintingStyle.fill;

    // ── Elevator system ──────────────────────────────────────────────────────
    final dy = elevatorY - 67.0; // negative = moved up
    canvas.save();
    canvas.translate(0, dy);

    // Platform
    p.color = const Color(0xFF475569);
    _rr(canvas, p, 12, 67, 42, 2.2, 0.5);
    p.color = const Color(0xFF94A3B8);
    _rr(canvas, p, 12, 67, 42, 0.7, 0);

    // Product sitting on the elevator platform
    if (productOnElevator && selectedIdx >= 0) {
      final sp = products[selectedIdx];
      // In translated space: product y = 67 - 11 = 56
      _drawProduct(canvas, p, sp.x, 56.0, sp.color);
    }

    canvas.restore();

    // ── UI side panel ────────────────────────────────────────────────────────
    p.color = const Color(0xFF0F172A);
    _rr(canvas, p, 58, 18, 13, 23, 2);

    // Panel highlight
    p.color = Colors.white.withOpacity(0.06);
    _rr(canvas, p, 58.5, 18.5, 6, 23, 0);

    // Screen
    p.color = const Color.fromARGB(255, 255, 255, 255);
    _rr(canvas, p, 60, 22, 9, 16, 1.5);
    // Screen scanline glow
    p.color = const Color.fromARGB(255, 255, 255, 255).withOpacity(0.6);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    _rr(canvas, p, 61, 23, 7, 14, 1);
    p.maskFilter = null;
    // Screen content
    p.color = const Color(0xFFF47B20);
    _rr(canvas, p, 60.5, 23.5, 8, 2, 0.4);
    p.color = const Color(0xFF7DD3FC).withOpacity(0.6);
    _rr(canvas, p, 61, 27.5, 3, 3, 0.4);
    p.color = const Color.fromARGB(255, 252, 241, 125).withOpacity(0.8);
    _rr(canvas, p, 61, 32.5, 3, 3, 0.4);
    p.color = const Color.fromARGB(255, 165, 252, 125).withOpacity(0.6);
    _rr(canvas, p, 65, 27.5, 3, 3, 0.4);
    p.color = const Color.fromARGB(255, 180, 125, 252).withOpacity(0.6);
    _rr(canvas, p, 65, 32.5, 3, 3, 0.4);

    // Orange button
    // p.color = AppColors.grey;
    // _rr(canvas, p, 60, 45, 3.5, 7, 1);

    // POS reader
    p.color = AppColors.navy;
    _rr(canvas, p, 60, 44, 9, 9, 1);
    p.color = const Color.fromARGB(255, 220, 220, 220);
    _rr(canvas, p, 62, 45, 5, 7, 0.5);
    // p.color = const Color(0xFF9CA3AF);
    // _rr(canvas, p, 61, 48, 7, 0.8, 0.4);
    // _rr(canvas, p, 61, 50, 5, 0.8, 0.4);

    // Ventilation slots (bottom of panel)
    // p.color = const Color(0xFF334155);
    // for (double vy = 60; vy <= 68; vy += 3) {
    //   _rr(canvas, p, 60, vy, 9, 1, 0.3);
    // }

    // ── Delivery tray ────────────────────────────────────────────────────────
    // Tray interior
    p.color = const Color(0xFFCBD5E1);
    _rr(canvas, p, 17, 75, 32, 12, 1.5);
    p.color = const Color(0xFFE2E8F0);
    _rr(canvas, p, 17, 77, 32, 10, 1);
    // Bottom groove
    p.color = const Color(0xFFB0BEC5);
    _rr(canvas, p, 17, 85, 32, 2, 0);

    // Product sitting in tray after delivery
    if (productInTray && selectedIdx >= 0) {
      final sp = products[selectedIdx];
      _drawProduct(canvas, p, 28.5, 75.5, sp.color);
    }

    // ── Tray door (rolls down when opening) ────────────────────────────────────
    if (doorOpenAmount < 0.99) {
      final visH = 12.0 * (1.0 - doorOpenAmount);
      final doorBottom = 87.0 - (12.0 - visH); // slides downward from bottom
      p.color = const Color(0xFF334155);
      _rr(canvas, p, 17, doorBottom - visH, 32, visH, 1.5);
      // Door horizontal ridges
      p.color = const Color(0xFF475569);
      p.style = PaintingStyle.stroke;
      p.strokeWidth = 0.5;
      for (double ry = doorBottom - visH + 2; ry < doorBottom - 1; ry += 2.5) {
        canvas.drawLine(Offset(18, ry), Offset(48, ry), p);
      }
      p.style = PaintingStyle.fill;
      // Door border
      p.color = Colors.black.withOpacity(0.35);
      p.style = PaintingStyle.stroke;
      p.strokeWidth = 0.5;
      _rr(canvas, p, 17, doorBottom - visH, 32, visH, 1.5);
      p.style = PaintingStyle.fill;
    }

    // ── Top highlight ────────────────────────────────────────────────────────
    p.color = Colors.white.withOpacity(0.55);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 0.8;
    canvas.drawLine(const Offset(9, 6.5), const Offset(71, 6.5), p);
    p.style = PaintingStyle.fill;
  }

  void _drawProduct(Canvas canvas, Paint p, double x, double y, Color color) {
    // Body
    p.color = color;
    _rr(canvas, p, x, y, 7, 11, 1.8);
    // Top gloss
    p.color = Colors.white.withOpacity(0.28);
    _rr(canvas, p, x + 1, y + 1, 5, 3.5, 1);
    // Bottom shadow
    p.color = Colors.black.withOpacity(0.15);
    _rr(canvas, p, x, y + 8, 7, 3, 1.8);
  }

  void _rr(
    Canvas canvas,
    Paint p,
    double x,
    double y,
    double w,
    double h,
    double r,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      p,
    );
  }

  @override
  bool shouldRepaint(_VendingMachinePainter old) =>
      old.elevatorY != elevatorY ||
      old.selectedIdx != selectedIdx ||
      old.productOnElevator != productOnElevator ||
      old.productInTray != productInTray ||
      old.doorOpenAmount != doorOpenAmount;
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple background blob widget
// ─────────────────────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final double opacity;
  const _Blob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.orange.withOpacity(0.2),
        ),
      ),
    );
  }
}

