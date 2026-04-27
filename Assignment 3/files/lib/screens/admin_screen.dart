import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bmi_record.dart';
import '../providers/bmi_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/bmi_utils.dart';
import '../widgets/dashed_panel.dart';

const _defaultAdminUsername = 'admin';
const _defaultAdminPassword = 'admin123';
const _kAdminUsername = 'adminUsername';
const _kAdminPassword = 'adminPassword';
const _months = [
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

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _settingsUsernameCtrl;
  late final TextEditingController _settingsPasswordCtrl;
  bool _loggedIn = false;
  bool _isLoggingIn = false;
  bool _obscurePassword = true;
  bool _obscureSettingsPassword = true;
  String? _error;
  String _adminUsername = _defaultAdminUsername;
  String _adminPassword = _defaultAdminPassword;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _settingsUsernameCtrl = TextEditingController();
    _settingsPasswordCtrl = TextEditingController();
    _loadCredentials();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _settingsUsernameCtrl.dispose();
    _settingsPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_kAdminUsername) ?? _defaultAdminUsername;
    final password = prefs.getString(_kAdminPassword) ?? _defaultAdminPassword;
    if (!mounted) return;
    setState(() {
      _adminUsername = username;
      _adminPassword = password;
      _settingsUsernameCtrl.text = username;
      _settingsPasswordCtrl.text = password;
    });
  }

  Future<void> _login() async {
    if (_isLoggingIn) return;
    HapticFeedback.mediumImpact();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      _showAdminMessage(
        'Username and password cannot be empty.',
        icon: FeatherIcons.alertCircle,
        accent: context.read<ThemeProvider>().colors.destructive,
      );
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _error = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (username == _adminUsername && password == _adminPassword) {
      setState(() {
        _loggedIn = true;
        _isLoggingIn = false;
        _error = null;
      });
      _showAdminMessage('Welcome admin');
      return;
    }

    setState(() {
      _isLoggingIn = false;
      _error = 'Wrong admin username or password.';
      _loggedIn = false;
    });
  }

  Future<void> _saveCredentials() async {
    HapticFeedback.mediumImpact();
    final username = _settingsUsernameCtrl.text.trim();
    final password = _settingsPasswordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      _showAdminMessage(
        'Username and password cannot be empty.',
        icon: FeatherIcons.alertCircle,
        accent: context.read<ThemeProvider>().colors.destructive,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAdminUsername, username);
    await prefs.setString(_kAdminPassword, password);

    if (!mounted) return;
    setState(() {
      _adminUsername = username;
      _adminPassword = password;
      _error = null;
    });
    _showAdminMessage(
      'Admin credentials updated.',
      icon: FeatherIcons.checkCircle,
    );
  }

  void _logout() {
    HapticFeedback.lightImpact();
    setState(() {
      _loggedIn = false;
      _isLoggingIn = false;
      _obscurePassword = true;
      _obscureSettingsPassword = true;
      _passwordCtrl.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final bmiP = context.watch<BMIProvider>();
    final history = bmiP.history;
    final media = MediaQuery.of(context);
    final topPad = media.padding.top + 16;
    final bottomPad = media.padding.bottom + 24;
    final avgBMI = history.isEmpty
        ? null
        : history.fold<double>(0, (sum, item) => sum + item.bmi) / history.length;
    final latest = history.isEmpty ? null : history.first;

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, topPad, 18, bottomPad),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: colors.cardBorder, width: 1.5),
                    ),
                    child: Icon(
                      FeatherIcons.arrowLeft,
                      size: 16,
                      color: colors.foreground,
                    ),
                  ),
                ),
                const Spacer(),
                if (_loggedIn)
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.muted,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FeatherIcons.logOut,
                            size: 12,
                            color: colors.mutedForeground,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Logout',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Admin',
              style: GoogleFonts.inter(
                fontSize: 40,
                height: 42 / 40,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
                color: colors.foreground,
              ),
            ),
            Text(
              _loggedIn ? 'Dashboard' : 'Access',
              style: GoogleFonts.inter(
                fontSize: 40,
                height: 42 / 40,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
                color: colors.foreground.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _loggedIn
                  ? 'Manage BMI results, update admin credentials, and remove saved records.'
                  : 'Sign in to review saved BMI results and manage admin tools.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 18),
            if (!_loggedIn) ...[
              _loginCard(colors),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      colors,
                      label: 'Saved Results',
                      value: '${history.length}',
                      color: colors.primary,
                      icon: FeatherIcons.database,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      colors,
                      label: 'Average BMI',
                      value: avgBMI?.toStringAsFixed(1) ?? '--',
                      color: avgBMI == null
                          ? colors.mutedForeground
                          : getBMIColorForPalette(colors, avgBMI),
                      icon: FeatherIcons.activity,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      colors,
                      label: 'Latest',
                      value: latest == null ? '--' : _dateLabel(latest.date),
                      color: colors.normal,
                      icon: FeatherIcons.clock,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _credentialsCard(colors),
              const SizedBox(height: 14),
              _sectionCard(
                colors: colors,
                title: 'Admin Actions',
                accent: colors.primary,
                trailing: history.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: () => _confirmClearAll(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.destructive.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color:
                                  colors.destructive.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FeatherIcons.trash2,
                                size: 11,
                                color: colors.destructive,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Delete All',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colors.destructive,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'All saved BMI results appear below with delete controls for admin cleanup.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 19 / 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _metaPill(colors, FeatherIcons.shield, 'Admin mode'),
                        _metaPill(
                          colors,
                          FeatherIcons.activity,
                          '${history.length} result${history.length == 1 ? "" : "s"}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (history.isEmpty)
                DashedPanel(
                  padding: const EdgeInsets.all(36),
                  borderRadius: BorderRadius.circular(24),
                  color: colors.border,
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colors.muted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FeatherIcons.inbox,
                          size: 30,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No Results Yet',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Saved BMI results will appear here once users calculate their BMI.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 21 / 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...history.asMap().entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == history.length - 1 ? 0 : 10,
                    ),
                    child: _adminRecordItem(
                      context,
                      colors,
                      entry.value,
                      entry.key,
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _loginCard(dynamic colors) {
    return _sectionCard(
      colors: colors,
      title: 'Login',
      accent: colors.primary,
      child: IgnorePointer(
        ignoring: _isLoggingIn,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              colors: colors,
              controller: _usernameCtrl,
              hint: 'Admin username',
              icon: FeatherIcons.user,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _field(
              colors: colors,
              controller: _passwordCtrl,
              hint: 'Password',
              icon: FeatherIcons.lock,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: _isLoggingIn ? null : (_) => _login(),
              trailing: GestureDetector(
                onTap:
                    () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword ? FeatherIcons.eye : FeatherIcons.eyeOff,
                  size: 16,
                  color: colors.mutedForeground,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.destructive,
                ),
              ),
            ],
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _isLoggingIn ? null : _login,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isLoggingIn
                      ? colors.primary.withValues(alpha: 0.7)
                      : colors.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.28),
                      offset: const Offset(0, 10),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoggingIn)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(
                        FeatherIcons.shield,
                        size: 18,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _isLoggingIn ? 'Logging in...' : 'Login as Admin',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _credentialsCard(dynamic colors) {
    return _sectionCard(
      colors: colors,
      title: 'Admin Credentials',
      accent: colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            colors: colors,
            controller: _settingsUsernameCtrl,
            hint: 'New admin username',
            icon: FeatherIcons.user,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _field(
            colors: colors,
            controller: _settingsPasswordCtrl,
            hint: 'New admin password',
            icon: FeatherIcons.lock,
            obscureText: _obscureSettingsPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveCredentials(),
            trailing: GestureDetector(
              onTap: () => setState(
                  () => _obscureSettingsPassword = !_obscureSettingsPassword),
              child: Icon(
                _obscureSettingsPassword
                    ? FeatherIcons.eye
                    : FeatherIcons.eyeOff,
                size: 16,
                color: colors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _saveCredentials,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.28),
                    offset: const Offset(0, 10),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FeatherIcons.save, size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Save Credentials',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required dynamic colors,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Widget? trailing,
    bool obscureText = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, size: 15, color: colors.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({
    required dynamic colors,
    required String title,
    required Color accent,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _metaPill(dynamic colors, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: colors.mutedForeground),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    dynamic colors, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminRecordItem(
    BuildContext context,
    dynamic colors,
    BMIRecord item,
    int index,
  ) {
    final bmiColor = getBMIColorForPalette(colors, item.bmi);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bmiColor.withValues(alpha: 0.16), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bmiColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: bmiColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.bmi.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 18 / 16,
                    fontWeight: FontWeight.w700,
                    color: bmiColor,
                  ),
                ),
                Text(
                  getBMIShortLabel(item.bmi).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: bmiColor.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fullDateLabel(item.date),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.muted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _metaPill(colors, FeatherIcons.maximize2, '${item.height} cm'),
                    _metaPill(
                      colors,
                      FeatherIcons.database,
                      '${item.weight.toStringAsFixed(1)} kg',
                    ),
                    _metaPill(colors, FeatherIcons.shield, item.category),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _confirmDeleteRecord(context, item),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.destructive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.destructive.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                FeatherIcons.trash2,
                size: 15,
                color: colors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(String iso) {
    final date = DateTime.parse(iso).toLocal();
    return '${_months[date.month - 1]} ${date.day}';
  }

  String _fullDateLabel(String iso) {
    final date = DateTime.parse(iso).toLocal();
    final hh = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final mm = date.minute.toString().padLeft(2, '0');
    final meridiem = date.hour >= 12 ? 'PM' : 'AM';
    return '${_months[date.month - 1]} ${date.day}, ${date.year} - $hh:$mm $meridiem';
  }

  void _showAdminMessage(
    String message, {
    IconData icon = FeatherIcons.shield,
    Color? accent,
  }) {
    final colors = context.read<ThemeProvider>().colors;
    final highlight = accent ?? colors.primary;
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(icon, size: 16, color: highlight),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteRecord(BuildContext context, BMIRecord item) {
    HapticFeedback.heavyImpact();
    final bmiP = context.read<BMIProvider>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Result'),
        content: Text(
          'Delete the saved BMI result ${item.bmi.toStringAsFixed(1)} from ${_fullDateLabel(item.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bmiP.deleteHistoryRecord(item.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    HapticFeedback.heavyImpact();
    final bmiP = context.read<BMIProvider>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Results'),
        content: const Text('Remove every saved BMI result from admin history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bmiP.clearHistory();
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
