import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/core/errors/auth_failure.dart';
import 'package:petreminder_user/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:petreminder_user/providers/auth_providers.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';
import 'package:petreminder_user/services/email_verification_service.dart';

final emailVerificationServiceProvider = Provider(
  (ref) => EmailVerificationService(ref.watch(firebaseAuthProvider)),
);

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with WidgetsBindingObserver {
  bool _busy = false;
  String? _message;
  bool _error = false;
  DateTime? _resendAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) {
      _check(silent: true);
    }
  }

  Future<void> _check({bool silent = false}) => _run(() async {
    final verified = await ref.read(emailVerificationServiceProvider).refresh();
    if (!verified && !silent) {
      throw const AuthFailure(
        'Tu correo aún no está confirmado. Abre el enlace recibido y vuelve a comprobarlo.',
      );
    }
  }, silent ? '' : 'Correo confirmado.');

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
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
      await ref.read(emailVerificationServiceProvider).send();
    },
    'Enlace enviado. Revisa tu correo y la carpeta de spam, abre el enlace y regresa a la app.',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '1. Envía el enlace a tu correo.\n2. Abre el mensaje de PetReminder y confirma tu dirección.\n3. Regresa y pulsa «Ya confirmé mi correo».',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _busy || _remaining > 0 ? null : _send,
            child: Text(
              _remaining > 0
                  ? 'Reenviar en $_remaining s'
                  : 'Enviar enlace de confirmación',
            ),
          ),
          const SizedBox(height: 20),
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
            onPressed: _busy ? null : () => _check(),
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ya confirmé mi correo'),
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
    );
  }
}
