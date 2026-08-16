import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../session/session_controller.dart';

const double _gateMaxWidth = 320;
const double _gateIconSize = 40;

/// Gates the staff surface: shows a code entry until the correct staff access
/// code is entered, then the [child] (the waiter surface). A minimal guard until
/// real staff auth (Ebriza) lands, so the surface is not open to anyone who
/// knows the URL. Staff-facing, so its text stays Romanian like the surface.
class StaffGuard extends ConsumerWidget {
  final Widget child;
  const StaffGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStaff = ref.watch(sessionProvider.select((s) => s.isStaff));
    return isStaff ? child : const _StaffGate();
  }
}

class _StaffGate extends ConsumerStatefulWidget {
  const _StaffGate();

  @override
  ConsumerState<_StaffGate> createState() => _StaffGateState();
}

class _StaffGateState extends ConsumerState<_StaffGate> {
  final _controller = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = ref.read(appConfigProvider).staffAccessCode;
    if (_controller.text.trim() == code) {
      ref.read(sessionProvider.notifier).signInAsStaff();
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acces staff')),
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
                const Text('Introdu codul de acces al personalului'),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Cod',
                    border: const OutlineInputBorder(),
                    errorText: _wrong ? 'Cod greșit' : null,
                  ),
                  onChanged: (_) {
                    if (_wrong) setState(() => _wrong = false);
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _submit, child: const Text('Intră')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
