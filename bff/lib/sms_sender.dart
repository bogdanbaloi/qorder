import 'dart:io';

/// Delivers an OTP to a phone. The dev sender logs it (and the API echoes it in
/// the response for the demo); a real adapter (Twilio / Infobip / Viber) sends a
/// text, and the API stops echoing the code. Swapping is a composition-root
/// change, POS/provider-agnostic.
abstract interface class SmsSender {
  void send(String phone, String code);
}

/// No SMS: logs the code to stdout. Paired with the API echoing `devCode`, the
/// demo works without an SMS provider.
class DevSmsSender implements SmsSender {
  const DevSmsSender();

  @override
  void send(String phone, String code) {
    stdout.writeln('[dev-sms] OTP for $phone: $code');
  }
}
