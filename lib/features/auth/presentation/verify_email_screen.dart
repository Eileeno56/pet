import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:petreminder_user/core/errors/auth_failure.dart';
import 'package:petreminder_user/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:petreminder_user/providers/auth_providers.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';
import 'package:petreminder_user/services/email_verification_service.dart';

final emailVerificationServiceProvider = Provider(
  (ref) => EmailVerificationService(
    ref.watch(firebaseAuthProvider),
    FirebaseFunctions.instanceFor(region: 'us-central1'),
  ),
);

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _message;
  bool _error = false;
  DateTime? _resendAt;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action().timeout(const Duration(seconds: 40));
      if (!mounted) return;
      setState(() {
        _message = success;
        _error = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error is AuthFailure
            ? error.message
            : 'No fue posible completar la operación. Revisa tu conexión y vuelve a intentarlo.';
        _error = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(
    () async {
      // Cooldown also applies to uncertain network outcomes; the server is authoritative.
      setState(
        () => _resendAt = DateTime.now().add(const Duration(seconds: 60)),
      );
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {});
        if (_remaining == 0) timer.cancel();
      });
      _code.clear();
      await ref.read(emailVerificationServiceProvider).send();
    },
    'Código enviado. Revisa tu correo y la carpeta de spam. Vence en 10 minutos.',
  );

  int get _remaining => _resendAt == null
      ? 0
      : (_resendAt!.difference(DateTime.now()).inMilliseconds / 1000)
            .ceil()
            .clamp(0, 60);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;
    return AuthScaffold(
      title: 'Confirma tu correo',
      subtitle:
          'Antes de entrar, confirma que tienes acceso a ${user?.email ?? 'tu correo'}.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Solicita un código de 5 dígitos y escríbelo aquí. No lo compartas con nadie.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _busy || _remaining > 0 ? null : _send,
              child: Text(
                _remaining > 0
                    ? 'Reenviar en $_remaining s'
                    : 'Enviar código al correo',
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _code,
              enabled: !_busy,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              decoration: const InputDecoration(
                labelText: 'Código de 5 dígitos',
                prefixIcon: Icon(Icons.mark_email_read_outlined),
              ),
              validator: (value) => RegExp(r'^\d{5}$').hasMatch(value ?? '')
                  ? null
                  : 'Escribe los 5 dígitos.',
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _error
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () {
                      if (_form.currentState?.validate() != true) return;
                      _run(
                        () => ref
                            .read(emailVerificationServiceProvider)
                            .verify(_code.text),
                        'Correo confirmado.',
                      );
                    },
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar correo'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      await ref
                          .read(emailVerificationServiceProvider)
                          .refresh();
                      if (ref
                              .read(firebaseAuthProvider)
                              .currentUser
                              ?.emailVerified !=
                          true) {
                        throw const AuthFailure(
                          'Tu correo aún no está confirmado. Solicita e introduce el código.',
                        );
                      }
                    }, 'Correo confirmado.'),
              child: const Text('Comprobar confirmación'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      final ok = await ref
                          .read(authControllerProvider.notifier)
                          .signOut();
                      if (!ok) {
                        throw const AuthFailure(
                          'No fue posible cerrar sesión. Inténtalo de nuevo.',
                        );
                      }
                    }, 'Sesión cerrada.'),
              child: const Text('Salir y usar otro correo'),
            ),
          ],
        ),
      ),
    );
  }
}
