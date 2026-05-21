import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart' show currentUser;

// ─────────────────────────────────────────────────────────────────────────────
// Data model — item order embedded in machine QR code
// ─────────────────────────────────────────────────────────────────────────────

class _ItemOrder {
  final String machineId;
  final String machineName;
  final String location;
  final String itemName;
  final double itemPrice;
  final String currency;
  final String transactionId;
  final String slot;

  const _ItemOrder({
    required this.machineId,
    required this.machineName,
    required this.location,
    required this.itemName,
    required this.itemPrice,
    required this.currency,
    required this.transactionId,
    required this.slot,
  });

  String get formattedPrice => '$currency ${itemPrice.toStringAsFixed(2)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen states
// ─────────────────────────────────────────────────────────────────────────────

enum _ScanState { scanning, found, error }

// ─────────────────────────────────────────────────────────────────────────────
// QR Screen — camera-based machine scanner
// ─────────────────────────────────────────────────────────────────────────────

class QrScreen extends StatefulWidget {
  final bool isActive;
  const QrScreen({super.key, this.isActive = false});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> with TickerProviderStateMixin {
  late final MobileScannerController _cam;
  late final AnimationController _lineCtrl;
  late final AnimationController _resultCtrl;
  late final AnimationController _flashCtrl;

  late final Animation<double> _scanLine;
  late final Animation<Offset> _resultSlide;
  late final Animation<double> _resultFade;
  late final Animation<double> _flash;

  _ScanState _state = _ScanState.scanning;
  bool _torchOn = false;
  bool _processing = false;
  _ItemOrder? _order;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();

    _cam = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: false,
    );

    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _scanLine = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut));

    _resultSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    _resultFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeIn));

    _flash = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));

    // Only start camera if this tab is already active on first build
    if (widget.isActive) {
      _activateCamera();
    }
  }

  void _activateCamera() {
    _lineCtrl.repeat();
    Future.microtask(() async {
      if (mounted) {
        try {
          await _cam.start();
        } catch (_) {}
      }
    });
  }

  void _deactivateCamera() {
    _lineCtrl.stop();
    _lineCtrl.reset();
    try {
      _cam.stop();
    } catch (_) {}
  }

  @override
  void didUpdateWidget(QrScreen old) {
    super.didUpdateWidget(old);
    if (widget.isActive == old.isActive) return;
    if (widget.isActive) {
      if (_state == _ScanState.scanning) _activateCamera();
    } else {
      _deactivateCamera();
    }
  }

  @override
  void dispose() {
    _cam.dispose();
    _lineCtrl.dispose();
    _resultCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  // ── Detection callback ─────────────────────────────────────────────────────

  void onDetect(BarcodeCapture capture) {
    if (_processing || _state != _ScanState.scanning) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _processing = true;
    _handleScan(raw);
  }

  void _handleScan(String raw) {
    final info = _parse(raw);
    if (info != null) {
      HapticFeedback.heavyImpact();
      _cam.stop();
      _flashCtrl.forward().then((_) => _flashCtrl.reverse());
      setState(() {
        _state = _ScanState.found;
        _order = info;
      });
      _resultCtrl.forward();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _state = _ScanState.error;
        _errorMsg = 'Not a valid ivend payment QR — select an item first';
        _processing = false;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _state = _ScanState.scanning);
      });
    }
  }

  // QR format from machine:
  //   ivend://pay?machine={serial}&slot={slot}&price={price_cents}&token={token}
  _ItemOrder? _parse(String raw) {
    try {
      if (raw.startsWith('ivend://pay?')) {
        final uri = Uri.parse(raw);
        final q = uri.queryParameters;

        // Current format: machine, slot, price, order_id
        final machine = q['machine'] ?? q['m'] ?? '';
        final slot = q['slot'] ?? q['s'] ?? '';
        final priceStr = q['price'] ?? q['p'] ?? '0';
        final token = q['order_id'] ?? q['token'] ?? q['o'] ?? '';

        if (machine.isEmpty || slot.isEmpty) return null;

        final priceCents = double.tryParse(priceStr) ?? 0;

        return _ItemOrder(
          machineId: machine,
          machineName: 'iVend Machine',
          location: '',
          itemName: 'Vending Item',
          itemPrice: priceCents / 100,
          currency: 'EGP',
          transactionId: token,
          slot: slot,
        );
      }
    } catch (_) {}
    return null;
  }

  void scanAgain() {
    setState(() {
      _state = _ScanState.scanning;
      _order = null;
      _processing = false;
    });
    _resultCtrl.reset();
    if (widget.isActive) _activateCamera();
  }

  // Demo: simulate a machine QR after item selection
  void _demoScan() {
    if (_state != _ScanState.scanning) return;
    _handleScan(
      'ivend:PAY:VM-CAI-001:City Stars – Floor 2:Near Entrance B:Pepsi 330ml:8.50:EGP:TXN-20260311-001',
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = (size.width * 0.72).clamp(220.0, 300.0);

    // The scan rect — centred slightly above middle, leaves room for panel
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.41),
      width: scanSize,
      height: scanSize,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Camera preview ─────────────────────────────────────────────
            RepaintBoundary(
              child: MobileScanner(controller: _cam, onDetect: onDetect),
            ),

            // ── Dark overlay with transparent scan cutout ──────────────────
            AnimatedBuilder(
              animation: _flashCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _OverlayPainter(
                  scanRect: scanRect,
                  found: _state == _ScanState.found,
                  flashValue: _flash.value,
                ),
              ),
            ),

            // ── Animated scan line (scanning state only) ───────────────────
            if (_state == _ScanState.scanning)
              AnimatedBuilder(
                animation: _scanLine,
                builder: (_, __) => Positioned(
                  left: scanRect.left + 6,
                  top: scanRect.top + (_scanLine.value * scanRect.height),
                  width: scanRect.width - 12,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.orange.withOpacity(0.85),
                          AppColors.orange,
                          AppColors.orange.withOpacity(0.85),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withOpacity(0.55),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Corner brackets ────────────────────────────────────────────
            ..._brackets(
              scanRect,
              _state == _ScanState.found ? AppColors.success : AppColors.orange,
            ),

            // ── Error badge ────────────────────────────────────────────────
            if (_state == _ScanState.error)
              Positioned(
                top: scanRect.bottom + 20,
                left: 40,
                right: 40,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _errorMsg ?? 'Invalid QR code',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Instruction text (scanning state only) ─────────────────────
            if (_state == _ScanState.scanning)
              Positioned(
                top: scanRect.bottom + 28,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'Point camera at the QR code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'on the machine screen after selecting your item',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.48),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Top bar ────────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // _TopBtn(
                    //   icon: Icons.arrow_back_rounded,
                    //   onTap: () => Navigator.pop(context),
                    // ),
                    Text(
                      _state == _ScanState.found
                          ? 'Confirm Payment'
                          : 'Scan to Pay',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _TopBtn(
                      icon: _torchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      active: _torchOn,
                      onTap: () {
                        _cam.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Machine result panel ────────────────────────────────────────
            if (_state == _ScanState.found && _order != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _resultSlide,
                  child: FadeTransition(
                    opacity: _resultFade,
                    child: _ResultPanel(
                      machine: _order!,
                      onScanAgain: scanAgain,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Corner bracket helpers ─────────────────────────────────────────────────

  List<Widget> _brackets(Rect r, Color color) {
    const s = 28.0;
    const w = 3.0;
    const radius = 5.0;

    Widget b(bool top, bool left) => Positioned(
      top: top ? r.top : r.bottom - s,
      left: left ? r.left : r.right - s,
      child: SizedBox(
        width: s,
        height: s,
        child: CustomPaint(
          painter: _BracketPainter(
            top: top,
            left: left,
            color: color,
            strokeWidth: w,
            radius: radius,
          ),
        ),
      ),
    );

    return [b(true, true), b(true, false), b(false, true), b(false, false)];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay painter — darkens outside the scan rect
// ─────────────────────────────────────────────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  final Rect scanRect;
  final bool found;
  final double flashValue;

  const _OverlayPainter({
    required this.scanRect,
    required this.found,
    required this.flashValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(scanRect, const Radius.circular(16));

    // Outer dim
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(rrect)
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withOpacity(0.62),
    );

    // Success green tint overlay on the whole screen
    if (flashValue > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = AppColors.success.withOpacity(flashValue * 0.25),
      );
    }

    // Scan area inner border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = (found ? AppColors.success : Colors.white).withOpacity(
           found ? 0.6 : 0.15,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.found != found || old.flashValue != flashValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment method enum
// ─────────────────────────────────────────────────────────────────────────────

enum _PayMethod { applePay, card, balance, points }

// ─────────────────────────────────────────────────────────────────────────────
// Machine result bottom panel — payment method selection
// ─────────────────────────────────────────────────────────────────────────────

class _ResultPanel extends StatefulWidget {
  final _ItemOrder machine;
  final VoidCallback onScanAgain;

  const _ResultPanel({required this.machine, required this.onScanAgain});

  @override
  State<_ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends State<_ResultPanel>
    with SingleTickerProviderStateMixin {
  bool _confirmed = false;
  _PayMethod? _chosen;
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  bool _paying = false;

  void _selectPayment(_PayMethod method) async {
    if (_paying) return;
    setState(() => _paying = true);
    HapticFeedback.heavyImpact();

    final success = await ApiService.payQR(
      machineId: widget.machine.machineId,
      slot: widget.machine.slot,
      priceCents: (widget.machine.itemPrice * 100).toInt(),
      orderId: widget.machine.transactionId,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _chosen = method;
        _confirmed = true;
        _paying = false;
      });
      _checkCtrl.forward();

      // Refresh wallet balance in background
      UserService.fetchBalance().then((balance) {
        if (balance != null) {
          currentUser.setBalance(balance);
        }
      });
    } else {
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please check your balance.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 14, 24, bottomPad + 16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: _confirmed
            ? _ConfirmedView(
                key: const ValueKey('confirmed'),
                machine: widget.machine,
                method: _chosen!,
                onScanAgain: widget.onScanAgain,
                checkScale: _checkScale,
              )
            : _ChooseView(
                key: const ValueKey('choose'),
                machine: widget.machine,
                onScanAgain: widget.onScanAgain,
                onPay: _selectPayment,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — choose payment method
// ─────────────────────────────────────────────────────────────────────────────

class _ChooseView extends StatelessWidget {
  final _ItemOrder machine;
  final VoidCallback onScanAgain;
  final ValueChanged<_PayMethod> onPay;

  const _ChooseView({
    super.key,
    required this.machine,
    required this.onScanAgain,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Item card — what the user is buying
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.originalCream, AppColors.originalCreamMid],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.navy,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine.itemName,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 11,
                          color: AppColors.navy.withOpacity(0.5),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            machine.location.isNotEmpty
                                ? machine.location
                                : machine.machineName,
                            style: TextStyle(
                              color: AppColors.navy.withOpacity(0.5),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                machine.formattedPrice,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Pay with Wallet',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Your item is ready — tap below to pay from your wallet balance',
          style: TextStyle(color: AppColors.grey, fontSize: 12),
        ),
        const SizedBox(height: 14),

        _PayTile(
          method: _PayMethod.balance,
          onTap: () => onPay(_PayMethod.balance),
        ),
        const SizedBox(height: 8),

        Center(
          child: TextButton(
            onPressed: onScanAgain,
            child: const Text(
              'Scan a different machine',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment method tile
// ─────────────────────────────────────────────────────────────────────────────

class _PayTile extends StatelessWidget {
  final _PayMethod method;
  final VoidCallback onTap;

  const _PayTile({required this.method, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isApplePay = method == _PayMethod.applePay;

    late final IconData icon;
    late final String title;
    String? subtitle;
    late final Color iconBg;
    late final Color iconColor;
    Color? subtitleColor;

    switch (method) {
      case _PayMethod.applePay:
        icon = Icons.apple;
        title = 'Apple Pay';
        iconBg = Colors.white.withOpacity(0.15);
        iconColor = Colors.white;
      case _PayMethod.card:
        icon = Icons.credit_card_rounded;
        title = 'Pay by Card';
        subtitle = 'Visa, Mastercard, Amex';
        iconBg = AppColors.orange.withOpacity(0.1);
        iconColor = AppColors.orange;
        subtitleColor = AppColors.grey;
      case _PayMethod.balance:
        icon = Icons.account_balance_wallet_rounded;
        title = 'Account Balance';
        subtitle = 'EGP ${currentUser.walletBalance.toStringAsFixed(2)} available';
        iconBg = AppColors.originalCream.withOpacity(0.07);
        iconColor = AppColors.navy;
        subtitleColor = AppColors.success;
      case _PayMethod.points:
        icon = Icons.stars_rounded;
        title = 'Points';
        subtitle = '2,450 pts  ≈  EGP 24.50';
        iconBg = AppColors.orange.withOpacity(0.1);
        iconColor = AppColors.orange;
        subtitleColor = AppColors.grey;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isApplePay ? Colors.black : AppColors.offWhite,
          borderRadius: BorderRadius.circular(16),
          border: isApplePay
              ? null
              : Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isApplePay ? Colors.white : iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isApplePay ? Colors.white : AppColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isApplePay
                            ? Colors.white.withOpacity(0.55)
                            : (subtitleColor ?? AppColors.grey),
                        fontSize: 12,
                        fontWeight: method == _PayMethod.balance
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isApplePay
                  ? Colors.white.withOpacity(0.4)
                  : AppColors.grey.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — payment confirmed, instruct user to use machine
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmedView extends StatelessWidget {
  final _ItemOrder machine;
  final _PayMethod method;
  final VoidCallback onScanAgain;
  final Animation<double> checkScale;

  const _ConfirmedView({
    super.key,
    required this.machine,
    required this.method,
    required this.onScanAgain,
    required this.checkScale,
  });

  String get _methodLabel => switch (method) {
    _PayMethod.applePay => 'Apple Pay',
    _PayMethod.card => 'Card',
    _PayMethod.balance => 'Account Balance',
    _PayMethod.points => 'Points',
  };

  IconData get _methodIcon => switch (method) {
    _PayMethod.applePay => Icons.apple,
    _PayMethod.card => Icons.credit_card_rounded,
    _PayMethod.balance => Icons.account_balance_wallet_rounded,
    _PayMethod.points => Icons.stars_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 28),

        // Animated success icon
        ScaleTransition(
          scale: checkScale,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 52,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Payment confirmed!',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your ${machine.itemName} is being dispensed',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grey, fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Payment method badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_methodIcon, color: AppColors.orange, size: 16),
              const SizedBox(width: 8),
              Text(
                'Paying with $_methodLabel',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Tray collection hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.success.withOpacity(0.18),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.move_to_inbox_rounded,
                size: 18,
                color: AppColors.success,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Collect your item from the tray at the bottom of the machine.',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Done button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navigate back to home route to reset tab index to 0 (Dashboard)
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.offWhite,
              foregroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Done'),
          ),
        ),
        const SizedBox(height: 4),

        TextButton(
          onPressed: onScanAgain,
          child: const Text(
            'Scan another item',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _TopBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? AppColors.orange.withOpacity(0.2)
              : Colors.black.withOpacity(0.42),
          border: Border.all(
            color: active
                ? AppColors.orange.withOpacity(0.5)
                : Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: active ? AppColors.orange : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Corner bracket painter (L-shaped corner marks)
// ─────────────────────────────────────────────────────────────────────────────

class _BracketPainter extends CustomPainter {
  final bool top;
  final bool left;
  final Color color;
  final double strokeWidth;
  final double radius;

  _BracketPainter({
    required this.top,
    required this.left,
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path
        ..moveTo(0, size.height)
        ..lineTo(0, radius)
        ..arcToPoint(
          Offset(radius, 0),
          radius: Radius.circular(radius),
          clockwise: true,
        )
        ..lineTo(size.width, 0);
    } else if (top && !left) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width - radius, 0)
        ..arcToPoint(
          Offset(size.width, radius),
          radius: Radius.circular(radius),
          clockwise: true,
        )
        ..lineTo(size.width, size.height);
    } else if (!top && left) {
      path
        ..moveTo(0, 0)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(
          Offset(radius, size.height),
          radius: Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width - radius, size.height)
        ..arcToPoint(
          Offset(size.width, size.height - radius),
          radius: Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
}

