import 'package:flutter/material.dart';

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          minimumSize: const Size.fromHeight(54),
        ),
      ),
    );
  }
}
