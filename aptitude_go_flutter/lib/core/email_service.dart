import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailService {
  static final EmailService instance = EmailService._init();
  EmailService._init();

  bool _initialized = false;
  String? _smtpHost;
  int _smtpPort = 587;
  String? _smtpUser;
  String? _smtpPassword;
  String? _fromName;

  Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
      _smtpHost = dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
      _smtpPort = int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
      _smtpUser = dotenv.env['SMTP_USER'] ?? 'aptitudego.official@gmail.com';
      _smtpPassword = dotenv.env['SMTP_PASSWORD'] ?? '';
      _fromName = dotenv.env['SMTP_FROM_NAME'] ?? 'Aptitude GO';
      _initialized = true;

      debugPrint('[EmailService] Initialized: host=$_smtpHost port=$_smtpPort user=$_smtpUser');
      if (_smtpPassword == null || _smtpPassword!.isEmpty) {
        debugPrint('[EmailService] WARNING: SMTP_PASSWORD is empty! Emails will fail.');
        debugPrint('[EmailService] Set SMTP_PASSWORD in .env file with a valid Google App Password.');
        debugPrint('[EmailService] Get one at: https://myaccount.google.com/apppasswords');
      }
    } catch (e) {
      debugPrint('[EmailService] Failed to load .env: $e');
      _initialized = false;
    }
  }

  bool get isReady => _initialized && (_smtpPassword?.isNotEmpty ?? false);

  Future<Map<String, dynamic>> sendOtpEmail({
    required String toEmail,
    required String otp,
    String purpose = 'verify',
  }) async {
    if (!isReady) {
      debugPrint('[EmailService] NOT READY — credentials not loaded. Set up .env file.');
      return {'success': false, 'error': 'SMTP not configured. Create a .env file with SMTP credentials.'};
    }

    if (toEmail.isEmpty || otp.isEmpty) {
      return {'success': false, 'error': 'Email and OTP are required'};
    }

    final String subject;
    final String textBody;

    if (purpose == 'verify') {
      subject = 'Verify Your Aptitude GO Account';
      textBody = '''
Welcome to Aptitude GO!

Your verification code is:

    $otp

This code will expire in 5 minutes.

If you did not create this account, please ignore this email.

- Aptitude GO Team
''';
    } else {
      subject = 'Aptitude GO Password Reset Code';
      textBody = '''
We received a request to reset your password.

Your OTP code is:

    $otp

This code will expire in 5 minutes.

If you did not request a password reset, please ignore this email.

- Aptitude GO Team
''';
    }

    final htmlBody = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$subject</title>
</head>
<body style="margin:0;padding:0;background:#0f172a;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0f172a;padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="560" cellpadding="0" cellspacing="0"
          style="background:#1e293b;border-radius:20px;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,0.5);">
          <tr>
            <td style="background:linear-gradient(135deg,#6366f1,#8b5cf6);padding:32px 40px;text-align:center;">
              <h1 style="margin:0;font-size:28px;color:#fff;font-weight:800;letter-spacing:-0.5px;">
                Aptitude <span style="color:#c4b5fd;">GO</span>
              </h1>
              <p style="margin:8px 0 0;color:rgba(255,255,255,0.8);font-size:14px;">
                Sharpen your skills. Prove your potential.
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:40px;">
              <h2 style="margin:0 0 12px;font-size:22px;color:#f1f5f9;text-align:center;font-weight:700;">
                ${purpose == 'verify' ? 'Email Verification' : 'Password Reset'}
              </h2>
              <p style="margin:0 0 8px;color:#94a3b8;font-size:15px;text-align:center;line-height:1.6;">
                ${purpose == 'verify' ? 'Welcome to Aptitude GO.' : 'We received a request to reset your password.'}
              </p>
              <p style="margin:16px 0 8px;color:#94a3b8;font-size:14px;text-align:center;">
                ${purpose == 'verify' ? 'Your verification code is:' : 'Your OTP code is:'}
              </p>
              <div style="text-align:center;margin:24px 0;">
                <div style="display:inline-block;background:#0f172a;padding:16px 40px;border-radius:16px;border:2px dashed #6366f1;letter-spacing:12px;">
                  <span style="font-size:36px;font-weight:800;color:#c4b5fd;font-family:'Courier New',monospace;">
                    $otp
                  </span>
                </div>
              </div>
              <p style="color:#64748b;font-size:13px;text-align:center;line-height:1.6;margin:0 0 24px;">
                This code will expire in 5 minutes.
              </p>
              <hr style="border:none;border-top:1px solid rgba(255,255,255,0.08);margin:24px 0;">
              <p style="color:#475569;font-size:12px;text-align:center;margin:0;line-height:1.6;">
                ${purpose == 'verify' ? "If you didn't create an Aptitude GO account, you can safely ignore this email." : "If you did not request a password reset, please ignore this email."}<br>
                Never share this code with anyone.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background:#0f172a;padding:20px 40px;text-align:center;border-top:1px solid rgba(255,255,255,0.05);">
              <p style="margin:0;color:#334155;font-size:12px;">
                &copy; 2026 Aptitude GO &middot; aptitudego.official@gmail.com
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';

    debugPrint('[EmailService] SENDING EMAIL...');
    debugPrint('[EmailService]   To:       $toEmail');
    debugPrint('[EmailService]   Subject:  $subject');
    debugPrint('[EmailService]   OTP:      $otp');
    debugPrint('[EmailService]   From:     $_smtpUser');
    debugPrint('[EmailService]   SMTP:     $_smtpHost:$_smtpPort');

    try {
      final smtpServer = gmail(_smtpUser!, _smtpPassword!);

      final message = Message()
        ..from = Address(_smtpUser!, _fromName)
        ..recipients.add(toEmail)
        ..subject = subject
        ..text = textBody
        ..html = htmlBody;

      final sendReport = await send(message, smtpServer);

      debugPrint('[EmailService] EMAIL SENT SUCCESSFULLY');
      debugPrint('[EmailService]   Report: ${sendReport.toString()}');

      return {
        'success': true,
        'message': 'OTP sent to $toEmail. Check your inbox (and spam folder).',
        'otp_debug': otp,
      };
    } on SocketException catch (e) {
      debugPrint('[EmailService] CONNECTION ERROR — cannot reach SMTP server.');
      debugPrint('[EmailService]   Check internet connectivity.');
      debugPrint('[EmailService]   Error: $e');
      return {'success': false, 'error': 'Cannot connect to email server. Check your internet connection.'};
    } on SmtpClientAuthenticationException catch (e) {
      debugPrint('[EmailService] AUTHENTICATION FAILED');
      debugPrint('[EmailService]   The App Password may be revoked or expired.');
      debugPrint('[EmailService]   Generate a new one at: https://myaccount.google.com/apppasswords');
      debugPrint('[EmailService]   Error: $e');
      return {'success': false, 'error': 'Email authentication failed. Check SMTP_PASSWORD in .env file.'};
    } on SmtpClientCommunicationException catch (e) {
      debugPrint('[EmailService] SMTP COMMUNICATION ERROR');
      debugPrint('[EmailService]   Error: $e');
      return {'success': false, 'error': 'SMTP communication error: ${e.message}'};
    } on SmtpUnsecureException catch (e) {
      debugPrint('[EmailService] UNSUPPORTED CONFIGURATION');
      debugPrint('[EmailService]   Error: $e');
      return {'success': false, 'error': 'Could not establish secure connection to email server.'};
    } on MailerException catch (e) {
      debugPrint('[EmailService] MAILER ERROR');
      debugPrint('[EmailService]   Error: $e');
      return {'success': false, 'error': 'Mailer error: ${e.message}'};
    } catch (e) {
      debugPrint('[EmailService] UNEXPECTED ERROR');
      debugPrint('[EmailService]   Type: ${e.runtimeType}');
      debugPrint('[EmailService]   Error: $e');
      return {'success': false, 'error': 'Failed to send email: $e'};
    }
  }

  Future<Map<String, dynamic>> sendTestEmail(String toEmail) async {
    final testOtp = _generateOtp();
    debugPrint('[EmailService] Sending test email to $toEmail with OTP: $testOtp');
    return await sendOtpEmail(toEmail: toEmail, otp: testOtp, purpose: 'verify');
  }

  String _generateOtp() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((now % 900000) + 100000).toString();
  }
}
