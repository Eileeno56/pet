import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petreminder_user/core/validators/input_validators.dart';
import 'package:petreminder_user/providers/auth_providers.dart';
import 'package:petreminder_user/providers/care_space_providers.dart';
import 'package:petreminder_user/providers/profile_providers.dart';

class CareSharingScreen extends ConsumerStatefulWidget {
  const CareSharingScreen({super.key});
  @override
  ConsumerState<CareSharingScreen> createState() => _CareSharingScreenState();
}

class _CareSharingScreenState extends ConsumerState<CareSharingScreen> {
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action().timeout(const Duration(seconds: 18));
      if (mounted) setState(() => _message = success);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'No se pudo completar. Revisa tu conexión, la invitación y que tu correo esté verificado.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;
    final incoming = ref.watch(careInvitationsProvider);
    final outgoing = ref.watch(outgoingCareInvitationsProvider);
    final spaces = ref.watch(careSpacesProvider);
    final repository = ref.read(careSharingRepositoryProvider);
    final owner = ref.watch(careOwnerIdProvider);
    final profile = ref.watch(appUserProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Cuidado en familia')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.diversity_1_outlined, size: 50),
              const SizedBox(height: 12),
              Text(
                'Cuidar juntos es más fácil',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              const Text(
                'Invita a alguien por el correo con el que usa PetReminder. La invitación aparecerá dentro de su app; avísale para que entre a esta sección. No se envía un correo automático.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (user != null && !user.emailVerified)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Verifica tu correo para recibir y aceptar invitaciones.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  user.sendEmailVerification,
                                  'Enviamos el enlace de verificación a tu correo.',
                                ),
                          child: const Text('Enviar verificación'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  await user.reload();
                                  await user.getIdToken(true);
                                  ref.invalidate(authStateChangesProvider);
                                  ref.invalidate(careInvitationsProvider);
                                }, 'Correo actualizado.'),
                          child: const Text('Ya verifiqué mi correo'),
                        ),
                      ],
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Invitar a mis mascotas',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'La persona podrá consultar, editar y registrar el cuidado de tus mascotas, horarios, comidas y ficha médica. Puedes revocar su acceso aquí.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final error = InputValidators.email(value);
                            if (error != null) return error;
                            return value!.trim().toLowerCase() ==
                                    user?.email?.toLowerCase()
                                ? 'Escribe el correo de otra persona.'
                                : null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Correo de tu familiar',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _busy || user == null
                              ? null
                              : () {
                                  if (!_form.currentState!.validate()) return;
                                  _run(
                                    () => repository.invite(
                                      ownerId: user.uid,
                                      ownerName:
                                          profile?.name ??
                                          user.displayName ??
                                          'Familia',
                                      email: _email.text,
                                    ),
                                    'Invitación creada. Tu familiar puede aceptarla desde Cuidado en familia.',
                                  );
                                },
                          icon: const Icon(Icons.person_add_alt),
                          label: const Text('Crear invitación'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    semanticsLabel: _message,
                  ),
                ),
              if (_busy) const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
              Text(
                'Espacio de mascotas',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              Card(
                child: RadioGroup<String>(
                  groupValue: owner ?? '',
                  onChanged: _busy
                      ? (_) {}
                      : (value) {
                          ref
                              .read(careSpaceSelectionProvider.notifier)
                              .select(value == user?.uid ? null : value);
                          context.go('/');
                        },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: user?.uid ?? '',
                        title: const Text('Mis mascotas'),
                      ),
                      ...?spaces.value?.map(
                        (space) => RadioListTile<String>(
                          value: space['ownerId'] as String,
                          title: Text('Mascotas de ${space['ownerName']}'),
                          subtitle: const Text(
                            'El acceso depende de la autorización vigente',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Invitaciones recibidas',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              ..._items(
                incoming,
                empty: 'No hay invitaciones pendientes.',
                builder: (invite) => Card(
                  child: ListTile(
                    title: Text('Cuidar con ${invite['ownerName']}'),
                    subtitle: const Text(
                      'Al aceptar compartirás el cuidado de sus mascotas.',
                    ),
                    trailing: IconButton(
                      tooltip: 'Aceptar invitación',
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: _busy || user == null
                          ? null
                          : () => _run(
                              () => repository.accept(
                                invitationId: invite['id'] as String,
                                uid: user.uid,
                              ),
                              'Invitación aceptada. Selecciona el espacio compartido.',
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Invitaciones enviadas',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              ..._items(
                outgoing,
                empty: 'No has enviado invitaciones.',
                builder: (invite) => Card(
                  child: ListTile(
                    title: Text(invite['email'] as String),
                    subtitle: Text(switch (invite['status']) {
                      'accepted' => 'Aceptada',
                      'revoked' => 'Revocada',
                      _ => 'Pendiente',
                    }),
                    trailing: invite['status'] == 'revoked'
                        ? null
                        : IconButton(
                            tooltip: 'Revocar acceso',
                            icon: const Icon(Icons.person_remove_outlined),
                            onPressed: _busy || user == null
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Revocar acceso'),
                                        content: Text(
                                          '¿Retirar la invitación y el acceso de ${invite['email']}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Revocar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await _run(
                                        () => repository.revoke(
                                          ownerId: user.uid,
                                          invitationId: invite['id'] as String,
                                          memberId:
                                              invite['acceptedBy'] as String?,
                                        ),
                                        'Acceso revocado.',
                                      );
                                    }
                                  },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _items(
    AsyncValue<List<Map<String, dynamic>>> value, {
    required String empty,
    required Widget Function(Map<String, dynamic>) builder,
  }) => value.when(
    loading: () => [const Center(child: CircularProgressIndicator())],
    error: (_, _) => [
      const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No se pudieron cargar los datos. Revisa tu conexión y vuelve a entrar.',
          textAlign: TextAlign.center,
        ),
      ),
    ],
    data: (items) => items.isEmpty
        ? [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(empty, textAlign: TextAlign.center),
            ),
          ]
        : items.map(builder).toList(),
  );
}
