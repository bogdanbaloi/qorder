import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/identity/session.dart';
import '../settings/language_controller.dart';
import '../settings/app_bar_toggles.dart';
import 'session_controller.dart';

const double _gateMaxWidth = 320;
const double _gateIconSize = 40;

/// Gates a surface behind a [role]: shows a code entry until the session holds
/// that role, then the [child]. A minimal guard until real auth (Ebriza), so the
/// staff and owner surfaces are not open to anyone who knows the URL. Staff /
/// owner facing, so the text stays Romanian.
class RoleGuard extends ConsumerWidget {
  final AppRole role;
  final Widget child;
  const RoleGuard({required this.role, required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sessionProvider.select((s) => s.role));
    return current == role ? child : _AccessGate(role: role);
  }
}

class _AccessGate extends ConsumerStatefulWidget {
  final AppRole role;
  const _AccessGate({required this.role});

  @override
  ConsumerState<_AccessGate> createState() => _AccessGateState();
}

class _AccessGateState extends ConsumerState<_AccessGate> {
  final _controller = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final venueId = ref.read(appConfigProvider).venueId;
    final token = await ref
        .read(staffAuthServiceProvider)
        .authenticate(venueId, widget.role, _controller.text.trim());
    if (!mounted) return;
    if (token != null) {
      ref.read(sessionProvider.notifier).signInAs(widget.role, staffToken: token);
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final title = widget.role == AppRole.owner ? s.ownerAccess : s.staffAccess;
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: const [AppBarToggles()]),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _gateMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: _gateIconSize),
                const SizedBox(height: 12),
                Text(s.enterAccessCode),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: s.codeLabel,
                    border: const OutlineInputBorder(),
                    errorText: _wrong ? s.wrongCode : null,
                  ),
                  onChanged: (_) {
                    if (_wrong) setState(() => _wrong = false);
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _submit, child: Text(s.enterButton)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
