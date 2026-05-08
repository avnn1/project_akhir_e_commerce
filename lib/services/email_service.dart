import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // Email pengirim dan App Password Gmail
  static const String _smtpEmail = 'git10844@gmail.com';
  static const String _smtpPassword = 'ojdnypxmpbemkczu';

  // Fungsi untuk mengenerate 6 digit OTP acak
  static String generateOTP() {
    Random random = Random();
    int otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  // Fungsi untuk mengirim email OTP
  static Future<bool> sendOTPEmail(String recipientEmail, String otp) async {
    final smtpServer = gmail(_smtpEmail, _smtpPassword);

    final message = Message()
      ..from = Address(_smtpEmail, 'Admin E-Commerce')
      ..recipients.add(recipientEmail)
      ..subject = 'Kode Verifikasi OTP Anda'
      ..html =
          '''
        <div style="font-family: Arial, sans-serif; padding: 20px; text-align: center;">
          <h2>Verifikasi Akun E-Commerce</h2>
          <p>Terima kasih telah mendaftar. Berikut adalah kode OTP Anda:</p>
          <h1 style="color: #4CAF50; font-size: 32px; letter-spacing: 5px;">$otp</h1>
          <p>Kode ini berlaku selama 5 menit.</p>
          <p>Kode ini bersifat rahasia. Jangan berikan kepada siapapun.</p>
        </div>
      ''';

    try {
      debugPrint('Mencoba mengirim OTP ke $recipientEmail ...');
      final sendReport = await send(message, smtpServer);
      debugPrint('OTP BERHASIL DIKIRIM ke $recipientEmail');
      debugPrint('Report: $sendReport');
      return true;
    } on MailerException catch (e) {
      debugPrint('===== GAGAL KIRIM EMAIL (MailerException) =====');
      debugPrint('Error: ${e.message}');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
      debugPrint('================================================');
      return false;
    } catch (e) {
      debugPrint('===== ERROR TIDAK TERDUGA =====');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('===============================');
      return false;
    }
  }
}
