import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../main.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String role;
  final String actualOtp;

  const VerifyOtpScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.actualOtp,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _verifyAndRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_otpController.text.trim() == widget.actualOtp) {
        // OTP Cocok, Lanjutkan pendaftaran
        final authService = context.read<AuthService>();
        final error = await authService.register(
          widget.name,
          widget.email,
          widget.password,
          widget.role,
        );

        if (mounted) {
          if (error == null) {
            // Sukses, kembali ke root (main.dart akan mengarahkan berdasarkan state login)
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Mendaftar: $error')));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode OTP Salah. Silakan coba lagi.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Email'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_read_outlined, size: 64, color: MyApp.primaryColor),
                const SizedBox(height: 28),
                const Text(
                  'Masukkan OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kami telah mengirimkan 6 digit kode OTP ke email Anda:\n\${widget.email}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Kode OTP 6 Digit',
                    alignLabelWithHint: true,
                    counterText: '',
                  ),
                  validator: (value) => value!.length != 6 ? 'Masukkan 6 digit angka' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: context.watch<AuthService>().isLoading ? null : _verifyAndRegister,
                    child: context.watch<AuthService>().isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Verifikasi & Daftar', style: TextStyle(fontSize: 16)),
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
