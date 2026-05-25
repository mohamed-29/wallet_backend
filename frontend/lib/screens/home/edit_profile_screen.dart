import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  double _collapseProgress = 0.0;
  static const double _expandedHeight = 180.0;
  static const double _fadeStart = 90.0;

  late final _nameCtrl = TextEditingController(text: currentUser.name);
  late final _emailCtrl = TextEditingController(text: currentUser.email);
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  bool _showCurrentPass = false;
  bool _showNewPass = false;
  bool _hasChanges = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    for (final c in [
      _nameCtrl,
      // _phoneCtrl,
      _emailCtrl,
      _currentPasswordCtrl,
      _newPasswordCtrl,
    ]) {
      c.addListener(() => setState(() => _hasChanges = true));
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
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    // _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    final newPass = _newPasswordCtrl.text;
    final currentPass = _currentPasswordCtrl.text;
    final newName = _nameCtrl.text.trim();
    final newEmail = _emailCtrl.text.trim();

    final nameChanged = newName != currentUser.name;
    final emailChanged = newEmail != currentUser.email;

    if (newPass.isNotEmpty && currentPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your current password to change it.')),
      );
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    // Persist personal info (name / email) if either changed.
    if (nameChanged || emailChanged) {
      final err = await UserService.updateProfile(
        name: nameChanged ? newName : null,
        email: emailChanged ? newEmail : null,
      );
      if (!mounted) return;
      if (err != null) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      if (nameChanged) currentUser.setName(newName);
      if (emailChanged) currentUser.setEmail(newEmail);
    }

    // Change password if a new one was entered.
    if (newPass.isNotEmpty) {
      final err = await UserService.changePassword(currentPass, newPass);
      if (!mounted) return;
      if (err != null) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
    }

    if (!mounted) return;
    setState(() => _saving = false);
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
            const Text(
              'Profile Updated',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your changes have been saved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────────────────
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
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.orange.withOpacity(
                                     0.12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(24, top + 16, 24, 28),
                            child: Row(
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
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Edit Profile',
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Update your personal info',
                                        style: TextStyle(
                                          color: AppColors.navyMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
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

            // ── Avatar row ────────────────────────────────────────────────────
            // SliverToBoxAdapter(
            //   child: Padding(
            //     padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            //     child: Center(
            //       child: Stack(
            //         children: [
            //           Container(
            //             width: 90,
            //             height: 90,
            //             decoration: BoxDecoration(
            //               shape: BoxShape.circle,
            //               gradient: const LinearGradient(
            //                 colors: [AppColors.orangeLight, AppColors.orangeDark],
            //               ),
            //               border: Border.all(color: AppColors.beige, width: 3),
            //               boxShadow: [
            //                 BoxShadow(
            //                   color: AppColors.orange.withOpacity(0.25),
            //                   blurRadius: 16,
            //                   offset: const Offset(0, 4),
            //                 ),
            //               ],
            //             ),
            //             child: const Center(
            //               child: Text(
            //                 'A',
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontSize: 36,
            //                   fontWeight: FontWeight.w700,
            //                 ),
            //               ),
            //             ),
            //           ),
            //           Positioned(
            //             bottom: 0,
            //             right: 0,
            //             child: Container(
            //               width: 30,
            //               height: 30,
            //               decoration: BoxDecoration(
            //                 color: AppColors.orange,
            //                 shape: BoxShape.circle,
            //                 border: Border.all(color: Colors.white, width: 2),
            //               ),
            //               child: const Icon(
            //                 Icons.camera_alt_rounded,
            //                 color: Colors.white,
            //                 size: 15,
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),

            // ── Form fields ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal info
                    const _SectionLabel(text: 'PERSONAL INFO'),
                    const SizedBox(height: 12),
                    _FieldGroup(
                      children: [
                        _ProfileField(
                          label: 'Full Name',
                          controller: _nameCtrl,
                          icon: Icons.person_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                        // _ProfileField(
                        //   label: 'Phone Number',
                        //   controller: _phoneCtrl,
                        //   icon: Icons.phone_rounded,
                        //   keyboardType: TextInputType.phone,
                        // ),
                        _ProfileField(
                          label: 'Email Address',
                          controller: _emailCtrl,
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Change password
                    const _SectionLabel(text: 'CHANGE PASSWORD'),
                    const SizedBox(height: 12),
                    _FieldGroup(
                      children: [
                        _ProfileField(
                          label: 'Current Password',
                          controller: _currentPasswordCtrl,
                          icon: Icons.lock_rounded,
                          obscure: !_showCurrentPass,
                          suffix: IconButton(
                            icon: Icon(
                              _showCurrentPass
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.grey,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _showCurrentPass = !_showCurrentPass,
                            ),
                          ),
                        ),
                        _ProfileField(
                          label: 'New Password',
                          controller: _newPasswordCtrl,
                          icon: Icons.lock_open_rounded,
                          obscure: !_showNewPass,
                          suffix: IconButton(
                            icon: Icon(
                              _showNewPass
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.grey,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _showNewPass = !_showNewPass),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedOpacity(
                        opacity: _hasChanges ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 220),
                        child: GestureDetector(
                          onTap: _hasChanges ? _save : null,
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
                                  color: AppColors.orange.withOpacity(
                                     0.35,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.grey.withOpacity(0.7),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final List<Widget> children;
  const _FieldGroup({required this.children});

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
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 58,
                endIndent: 0,
                color: AppColors.lightGrey,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.grey, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: AppColors.grey.withOpacity(0.8),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                suffixIcon: suffix,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                errorStyle: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

