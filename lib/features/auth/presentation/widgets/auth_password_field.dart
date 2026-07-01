import 'package:flutter/material.dart';

class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.label,
    required this.onChanged,
    this.controller,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
          tooltip: _obscure ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
        ),
      ),
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: widget.onChanged,
    );
  }
}
