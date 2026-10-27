import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petreminder_user/core/errors/pet_failure.dart';
import 'package:petreminder_user/core/pets/pet_catalog.dart';
import 'package:petreminder_user/core/validators/input_validators.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/providers/pet_providers.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  const PetFormScreen({super.key, this.pet});

  final Pet? pet;

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _monthsController;
  late final TextEditingController _customSpeciesController;
  late final TextEditingController _descriptionController;
  late String _species;
  String? _breedSelection;
  String? _selectedPhotoPath;
  bool _removeExistingPhoto = false;

  bool get _isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _nameController = TextEditingController(text: pet?.name);
    _breedController = TextEditingController(text: pet?.breed);
    _ageController = TextEditingController(text: pet?.age.toString() ?? '0');
    _monthsController = TextEditingController(
      text: pet?.ageMonths.toString() ?? '0',
    );
    _customSpeciesController = TextEditingController(text: pet?.customSpecies);
    _descriptionController = TextEditingController(text: pet?.description);
    _species = pet?.species ?? Pet.speciesOptions.first;
    if (!Pet.speciesOptions.contains(_species)) {
      _customSpeciesController.text = _species;
      _species = PetCatalog.other;
    }
    final breed = pet?.breed ?? '';
    _breedSelection = breed.isEmpty
        ? null
        : (PetCatalog.breeds[_species] ?? []).contains(breed) ||
              breed == 'Mestizo / Sin raza'
        ? breed
        : PetCatalog.other;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _monthsController.dispose();
    _customSpeciesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(petControllerProvider);
    final pets = ref.watch(petsProvider).value ?? const <Pet>[];
    final existingPhoto = widget.pet == null
        ? const AsyncData<String?>(null)
        : ref.watch(petPhotoPathProvider(widget.pet!.id));

    ref.listen(petControllerProvider, (previous, next) {
      if (!next.hasError || previous?.error == next.error) {
        return;
      }
      final error = next.error;
      final message = error is PetFailure
          ? error.message
          : 'No se pudo guardar la mascota.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });

    final visiblePhotoPath =
        _selectedPhotoPath ??
        (_removeExistingPhoto ? null : existingPhoto.value);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar mascota' : 'Agregar mascota'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _PhotoPreview(path: visiblePhotoPath),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: operation.isLoading
                              ? null
                              : () => _pickPhoto(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Cámara'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: operation.isLoading
                              ? null
                              : () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galería'),
                        ),
                      ),
                      if (visiblePhotoPath != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Quitar fotografía',
                          onPressed: operation.isLoading ? null : _removePhoto,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    enabled: !operation.isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.pets_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final error = InputValidators.petName(value);
                      if (error != null) return error;
                      final key = InputValidators.petNameKey(value!);
                      return pets.any(
                            (pet) =>
                                pet.id != widget.pet?.id &&
                                InputValidators.petNameKey(pet.name) == key,
                          )
                          ? 'Ya existe una mascota con ese nombre en este espacio.'
                          : null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _species,
                    decoration: const InputDecoration(
                      labelText: 'Especie',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: Pet.speciesOptions
                        .map(
                          (species) => DropdownMenuItem(
                            value: species,
                            child: Text(species),
                          ),
                        )
                        .toList(),
                    onChanged: operation.isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _species = value;
                                _breedSelection = null;
                                _breedController.clear();
                              });
                            }
                          },
                  ),
                  if (_species == PetCatalog.other) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('customSpecies'),
                      controller: _customSpeciesController,
                      enabled: !operation.isLoading,
                      maxLength: 40,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Escribe la especie',
                        border: OutlineInputBorder(),
                      ),
                      validator: InputValidators.customSpecies,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_species != PetCatalog.other)
                    DropdownButtonFormField<String>(
                      key: ValueKey('breed-$_species'),
                      initialValue: _breedSelection,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Raza o variedad',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                                ...PetCatalog.breeds[_species]!,
                                'Mestizo / Sin raza',
                                PetCatalog.other,
                              ]
                              .map(
                                (breed) => DropdownMenuItem(
                                  value: breed,
                                  child: Text(breed),
                                ),
                              )
                              .toList(),
                      onChanged: operation.isLoading
                          ? null
                          : (value) => setState(() => _breedSelection = value),
                      validator: (value) => value == null
                          ? 'Selecciona una raza o variedad.'
                          : null,
                    ),
                  if (_species == PetCatalog.other ||
                      _breedSelection == PetCatalog.other) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('customBreed'),
                      controller: _breedController,
                      enabled: !operation.isLoading,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 80,
                      decoration: InputDecoration(
                        labelText: _species == PetCatalog.other
                            ? 'Raza o variedad (opcional)'
                            : 'Escribe la raza o variedad',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          _species == PetCatalog.other &&
                              (value?.trim().isEmpty ?? true)
                          ? null
                          : InputValidators.petBreed(value),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextFormField(
                    key: _ageKey,
                    controller: _ageController,
                    enabled: !operation.isLoading,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 3,
                    decoration: const InputDecoration(
                      labelText: 'Edad en años',
                      prefixIcon: Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => InputValidators.petAge(
                      value,
                      species: _species,
                      months: int.tryParse(_monthsController.text) ?? 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const ValueKey('ageMonths'),
                    controller: _monthsController,
                    enabled: !operation.isLoading,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 2,
                    decoration: InputDecoration(
                      labelText: 'Meses adicionales (0 a 11)',
                      helperText:
                          'Edad máxima para $_species: ${PetCatalog.maximumYears(_species)} años. Para menores de un año, escribe 0 años.',
                      helperMaxLines: 3,
                      border: const OutlineInputBorder(),
                    ),
                    validator: InputValidators.petMonths,
                    onChanged: (_) => _ageKey.currentState?.validate(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !operation.isLoading,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: InputValidators.petDescription,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: operation.isLoading ? null : _submit,
                    icon: operation.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isEditing ? 'Guardar cambios' : 'Agregar mascota',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final path = await ref.read(petPhotoServiceProvider).pickPhoto(source);
      if (path != null && mounted) {
        setState(() {
          _selectedPhotoPath = path;
          _removeExistingPhoto = false;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo seleccionar la fotografía.')),
      );
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoPath = null;
      _removeExistingPhoto = true;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final input = PetInput(
      name: _nameController.text,
      species: _species,
      breed: _species == PetCatalog.other || _breedSelection == PetCatalog.other
          ? _breedController.text
          : _breedSelection!,
      age: int.parse(_ageController.text),
      ageMonths: int.parse(_monthsController.text),
      customSpecies: _customSpeciesController.text,
      description: _descriptionController.text,
    );
    final controller = ref.read(petControllerProvider.notifier);
    final success = _isEditing
        ? await controller.updatePet(
            petId: widget.pet!.id,
            input: input,
            photoPath: _selectedPhotoPath,
            removePhoto: _removeExistingPhoto,
          )
        : await controller.createPet(
                input: input,
                photoPath: _selectedPhotoPath,
              ) !=
              null;

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: path == null
              ? Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 54,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Image.file(
                  File(path!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 54),
                  ),
                ),
        ),
      ),
    );
  }
}
