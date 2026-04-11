import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/core/constants/app_colors.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  static const routeName = '/create-account';

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create your Ashray account', style: textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Fill the details below to continue.',
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  style: textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter full name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter email.';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password.';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password.';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      final auth = context.read<AuthController>();
                      final ok = await auth.register(
                        fullName: _nameController.text,
                        email: _emailController.text,
                        phone: _phoneController.text,
                        password: _passwordController.text,
                      );
                      if (!mounted) return;
                      if (ok) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(auth.errorMessage ?? 'Create account failed.'),
                          ),
                        );
                      }
                    },
                    child: context.watch<AuthController>().isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.8,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create account'),
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
