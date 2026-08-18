import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_strings.dart';
import '../../di/providers.dart';
import '../../domain/identity/consent.dart';
import '../../domain/identity/customer_identity.dart';
import '../settings/language_controller.dart';
import '../settings/language_toggle.dart';
import '../table/customer_provider.dart';
import 'session_controller.dart';

/// Customer phone sign-in: enter a phone, get a one-time code (OTP), tick the
/// consent, verify. Two steps in one screen. Uses the mock identity service for
/// now (fixed demo code, no SMS); the port swap is invisible here.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _challengeId; // null = still on the phone step
  String? _devHint; // the dev code, while there is no SMS
  bool _loyaltyConsent = false;
  bool _marketingConsent = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final challenge = await ref
        .read(identityServiceProvider)
        .startSignIn(_phone.text.trim());
    if (!mounted) return;
    setState(() {
      _challengeId = challenge.challengeId;
      _devHint = challenge.devHint;
      _error = null;
    });
  }

  Future<void> _verify() async {
    final s = ref.read(stringsProvider);
    if (!_loyaltyConsent) {
      setState(() => _error = s.consentLoyalty);
      return;
    }
    // Only a failed OTP is a "wrong code". The consent write below is best-effort
    // and must not undo the sign-in or read as a wrong code (that showed "Wrong
    // code" on a correct code, and the single-use code was already spent).
    final CustomerIdentity identity;
    try {
      identity = await ref
          .read(identityServiceProvider)
          .verify(
            _challengeId!,
            _code.text.trim(),
            clientId: ref.read(clientIdProvider),
          );
    } on Exception {
      if (!mounted) return;
      setState(() => _error = s.otpWrong);
      return;
    }
    ref.read(sessionProvider.notifier).signInCustomer(identity);
    await _recordConsent(identity.customerId);
    if (!mounted) return;
    context.pop();
  }

  /// Records the per-purpose consent for the signed-in customer. Best-effort: a
  /// failure here does not block or reverse the sign-in (it can be re-recorded).
  Future<void> _recordConsent(String customerId) async {
    final cfg = ref.read(appConfigProvider);
    try {
      await ref.read(consentSourceProvider).setConsent(cfg.venueId, customerId, [
        const Consent(purpose: ConsentPurpose.loyalty, granted: true),
        Consent(purpose: ConsentPurpose.marketing, granted: _marketingConsent),
      ]);
    } on Exception {
      // Consent can be re-recorded later; never fail the sign-in for it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.signInTitle),
        actions: const [LanguageToggle()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            enabled: _challengeId == null,
            decoration: InputDecoration(
              labelText: s.phoneLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_challengeId == null)
            FilledButton(onPressed: _sendCode, child: Text(s.sendCode))
          else
            ..._codeStep(s),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _codeStep(AppStrings s) => [
    TextField(
      controller: _code,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: s.codeLabel,
        helperText: _devHint == null ? null : s.demoCodeIs(_devHint!),
        border: const OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 8),
    CheckboxListTile(
      value: _loyaltyConsent,
      onChanged: (v) => setState(() => _loyaltyConsent = v ?? false),
      title: Text(s.consentLoyalty),
      contentPadding: EdgeInsets.zero,
    ),
    CheckboxListTile(
      value: _marketingConsent,
      onChanged: (v) => setState(() => _marketingConsent = v ?? false),
      title: Text(s.consentMarketing),
      contentPadding: EdgeInsets.zero,
    ),
    const SizedBox(height: 8),
    FilledButton(onPressed: _verify, child: Text(s.enterButton)),
  ];
}
