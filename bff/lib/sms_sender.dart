import 'dart:io';

/// Delivers an OTP to a phone. The dev sender logs it (and the API echoes it in
/// the response for the demo); a real adapter (Twilio / Infobip / Viber) sends a
/// text, and the API stops echoing the code. Swapping is a composition-root
/// change, POS/provider-agnostic.
abstract interface class SmsSender {
  void send(String phone, String code);
}

/// No SMS: logs the code to stdout. DEMO ONLY. Paired with the API echoing
/// `devCode`, the demo works without an SMS provider. It prints the code, so it
/// must never run in production (see [SilentSmsSender]).
class DevSmsSender implements SmsSender {
  const DevSmsSender();

  @override
  void send(String phone, String code) {
    stdout.writeln('[dev-sms] OTP for $phone: $code');
  }
}

/// The safe production default until a real SMS provider is wired: it does not
/// print or forward the code, so the OTP never leaks through logs. It also does
/// not deliver, so OTP sign-in is inert until a real adapter (Twilio / Infobip)
/// replaces it. Fail closed, never leak.
class SilentSmsSender implements SmsSender {
  const SilentSmsSender();

  @override
  void send(String phone, String code) {}
}
