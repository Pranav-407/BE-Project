// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatefulWidget {
  final String placeholder;
  final String label;
  final bool isPassword;
  final bool enabled;
  final bool readOnly;
  final TextEditingController controller;
  final IconData prefixIcon;
  final int? maxLines;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.placeholder,
    this.onTap,
    this.enabled=true,
    required this.label,
    this.isPassword = false,
    this.readOnly = false,
    required this.controller,
    this.maxLines,
    this.keyboardType,
    required this.prefixIcon,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black87,
        ),
        keyboardType: widget.keyboardType,
        controller: widget.controller,
        maxLines: widget.maxLines ?? 1,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        onTap: widget.onTap,
        obscureText: widget.isPassword ? _obscureText : false,
        decoration: InputDecoration(
          constraints: const BoxConstraints(minHeight: 55),
          labelText: widget.label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.teal[700],
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          prefixIcon: Icon(
            widget.prefixIcon,
            color: Colors.teal[700],
            size: 20,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          hintText: widget.placeholder,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[400],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}