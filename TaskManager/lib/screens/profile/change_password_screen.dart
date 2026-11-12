
import 'package:flutter/material.dart';

import '../../services/profile_service.dart';
import '../../utils/validators.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ProfileService().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset,
                  size: 72,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cập nhật mật khẩu của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                _buildPasswordField(
                  label: 'Mật khẩu hiện tại',
                  controller: _currentPasswordController,
                  obscureText: _hideCurrentPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _hideCurrentPassword =
                      !_hideCurrentPassword;
                    });
                  },
                  validator:
                  AppValidators.validateCurrentPassword,
                ),
                const SizedBox(height: 16),

                _buildPasswordField(
                  label: 'Mật khẩu mới',
                  controller: _newPasswordController,
                  obscureText: _hideNewPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _hideNewPassword = !_hideNewPassword;
                    });
                  },
                  validator: (value) {
                    return AppValidators.validateNewPassword(
                      value,
                      _currentPasswordController.text,
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildPasswordField(
                  label: 'Xác nhận mật khẩu mới',
                  controller: _confirmPasswordController,
                  obscureText: _hideConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _hideConfirmPassword =
                      !_hideConfirmPassword;
                    });
                  },
                  validator: (value) {
                    return AppValidators.validateConfirmPassword(
                      value,
                      _newPasswordController.text,
                    );
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed:
                  _isLoading ? null : _changePassword,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Đổi mật khẩu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
