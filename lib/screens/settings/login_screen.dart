// Login and Register screen.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../i18n/i18n.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/glass/gradient_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final i18n = APPi18n.of(context)!;

    if (_isLogin) {
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(i18n.loginSuccess)),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? i18n.loginFailed),
          ),
        );
      }
    } else {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(i18n.passwordMismatch)),
        );
        return;
      }

      final success = await authProvider.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(i18n.registerSuccess)),
        );
        setState(() {
          _isLogin = true;
          _emailController.clear();
          _confirmPasswordController.clear();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? i18n.registerFailed),
          ),
        );
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isLogin ? i18n.loginTitle : i18n.registerTitle,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassContainer(
                  color: isDark ? Colors.white : Colors.black,
                  opacity: 0.15,
                  blur: 20,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary.withValues(alpha: 0.2),
                            ),
                            child: Icon(
                              _isLogin ? Icons.person : Icons.person_add,
                              size: 40,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _isLogin ? i18n.loginTitle : i18n.registerTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 32),
                          _buildTextField(
                            controller: _usernameController,
                            label: i18n.usernamePlaceholder,
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return i18n.pleaseEnterTitle;
                              }
                              if (value.trim().length < 3) {
                                return i18n.usernameTooShort;
                              }
                              return null;
                            },
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          if (!_isLogin)
                            _buildTextField(
                              controller: _emailController,
                              label: i18n.emailPlaceholder,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return i18n.pleaseEnterTitle;
                                }
                                final emailRegex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return i18n.invalidEmail;
                                }
                                return null;
                              },
                              textColor: textColor,
                            ),
                          if (!_isLogin) const SizedBox(height: 16),
                          _buildPasswordField(
                            controller: _passwordController,
                            label: i18n.passwordPlaceholder,
                            obscureText: _obscurePassword,
                            onToggle: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return i18n.pleaseEnterTitle;
                              }
                              if (value.length < 6) {
                                return i18n.passwordTooShort;
                              }
                              return null;
                            },
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          if (!_isLogin)
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: i18n.confirmPasswordPlaceholder,
                              obscureText: _obscureConfirmPassword,
                              onToggle: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return i18n.pleaseEnterTitle;
                                }
                                if (value != _passwordController.text) {
                                  return i18n.passwordMismatch;
                                }
                                return null;
                              },
                              textColor: textColor,
                            ),
                          if (!_isLogin) const SizedBox(height: 24),
                          _buildButton(
                            onPressed: authProvider.isLoading ? null : _submit,
                            text: _isLogin ? i18n.loginButton : i18n.registerButton,
                            colorScheme: colorScheme,
                            isLoading: authProvider.isLoading,
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isLogin ? i18n.noAccount : i18n.hasAccount,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.7),
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    required Color textColor,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: textColor.withValues(alpha: 0.05),
        border: Border.all(
          color: textColor.withValues(alpha: 0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: textColor.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            icon,
            color: textColor.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: textColor.withValues(alpha: 0.05),
        border: Border.all(
          color: textColor.withValues(alpha: 0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: textColor.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: textColor.withValues(alpha: 0.5),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
              color: textColor.withValues(alpha: 0.5),
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String text,
    required ColorScheme colorScheme,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
