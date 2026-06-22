import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../store/auth_provider.dart';
import '../models/models.dart';
import '../utils/platform_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String _step = 'phone';
  String _phone = '';
  String? _debugOtp;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    PlatformUtils.hapticMedium();
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    if (RegExp(r'^\d{10}$').hasMatch(phone)) {
      phone = '+91$phone';
    }
    if (!RegExp(r'^\+91\d{10}$').hasMatch(phone)) {
      _showError('Please enter a valid 10-digit phone number');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService().sendOtp(phone);
      final data = response.data;
      if (!mounted) return;
      _showSnack('OTP sent successfully (Simulated)');
      setState(() {
        _phone = phone;
        _step = 'otp';
        _debugOtp = data['debugOtp']?.toString();
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to send OTP. Please retry.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    PlatformUtils.hapticMedium();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('Please enter the 6-digit verification code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService().verifyOtp(_phone, otp);
      final data = response.data;
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false)
          .setAuth(token, user);

      if (!mounted) return;
      PlatformUtils.hapticSuccess();
      _showSnack('Login successful!');

      if (user.role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('OTP verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<AuthProvider>(context).isDarkMode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.back,
              color: theme.colorScheme.primary),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Logo
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('L',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to LaundryIndia',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'OTP-based secure login. No password required.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Form card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: _step == 'phone'
                    ? _buildPhoneForm(theme)
                    : _buildOtpForm(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enter Mobile Number',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _handleSendOtp(),
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.phone, size: 18),
            hintText: 'e.g. 9999999999',
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
            onPressed: _isLoading ? null : _handleSendOtp,
            child: _isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text('Send OTP Code',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        const Text('Developer test phone numbers:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.grey)),
        const SizedBox(height: 6),
        const Text('• +919999999999 : Seeded Admin User',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const Text('• Any other number: Creates a new customer account',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildOtpForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              const Text('We sent a 6-digit OTP code to:',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(_phone,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _step = 'phone'),
                child: const Text('Change Phone Number',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_debugOtp != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles,
                    color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simulated OTP: $_debugOtp\n(Or use bypass code: 123456)',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        const Text('Enter OTP Verification Code',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleVerifyOtp(),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 12),
          decoration: const InputDecoration(
            prefixIcon: Icon(LucideIcons.lock, size: 18),
            hintText: '123456',
            counterText: '',
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
            onPressed: _isLoading ? null : _handleVerifyOtp,
            child: _isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text('Verify & Log In',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
