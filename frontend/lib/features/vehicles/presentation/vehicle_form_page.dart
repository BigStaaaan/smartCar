import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/vehicle.dart';
import 'vehicle_form_art.dart';
import 'vehicle_images.dart';
import 'vehicle_provider.dart';
import 'vehicle_theme.dart';

class VehicleFormPage extends ConsumerStatefulWidget {
  const VehicleFormPage({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  ConsumerState<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends ConsumerState<VehicleFormPage>
    with TickerProviderStateMixin {
  static const _letters = ['أ', 'ب', 'د', 'ه', 'و'];
  final _form = GlobalKey<FormState>();
  final _information = GlobalKey();
  late final _make = TextEditingController(text: widget.vehicle?.details.make);
  late final _model =
      TextEditingController(text: widget.vehicle?.details.model);
  late final _color =
      TextEditingController(text: widget.vehicle?.details.color);
  late final _year =
      TextEditingController(text: widget.vehicle?.details.year?.toString());
  late final _originalPlate = widget.vehicle?.details.registrationNumber ?? '';
  late final _plateParts = RegExp(
          r'^\s*(\d{1,5})\s*(?:\|\s*)?([A-Za-z\u0600-\u06ff])\s*(?:\|\s*)?(\d{1,2})\s*$')
      .firstMatch(_originalPlate);
  late final _serial = TextEditingController(text: _plateParts?.group(1));
  late String? _letter = _plateParts?.group(2);
  late final _region = TextEditingController(text: _plateParts?.group(3));
  late final _capacity = TextEditingController(
    text: widget.vehicle?.details.passengerCapacity.toString() ?? '4',
  );
  late bool _customCapacity =
      !const [2, 3, 4, 5, 6].contains(int.tryParse(_capacity.text));
  late Uint8List? _photo = widget.vehicle?.details.photo;
  late Uint8List? _registrationPhoto =
      widget.vehicle?.details.registrationPhoto;
  late final _entry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  late final _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
  bool _saving = false;
  bool? _pickingRegistration;
  Vehicle? _saved;

  bool get _busy => _saving || _pickingRegistration != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entry.value = 1;
    } else if (_entry.value == 0 && !_entry.isAnimating) {
      _entry.forward();
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _make,
      _model,
      _color,
      _year,
      _serial,
      _region,
      _capacity
    ]) {
      controller.dispose();
    }
    _entry.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source, {required bool registration}) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _pickingRegistration = registration);
    try {
      final bytes = await ref.read(vehicleImagePickerProvider)(
        source,
        maxDimension: registration ? 2400 : 1600,
      );
      if (!mounted || bytes == null) return;
      setState(() {
        if (registration) {
          _registrationPhoto = bytes;
        } else {
          _photo = bytes;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Impossible de charger cette image. Essayez une autre photo.'),
      ));
    } finally {
      if (mounted) setState(() => _pickingRegistration = null);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      final reduced = MediaQuery.disableAnimationsOf(context);
      if (!reduced) _shake.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _information.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(target,
              duration:
                  reduced ? Duration.zero : const Duration(milliseconds: 350));
        }
      });
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await ref.read(vehiclesProvider.notifier).save(
        (
          make: _make.text.trim(),
          model: _model.text.trim(),
          color: _color.text.trim(),
          year: int.tryParse(_year.text),
          registrationNumber: '${_serial.text} | $_letter | ${_region.text}',
          passengerCapacity: int.parse(_capacity.text.trim()),
          photo: _photo,
          registrationPhoto: _registrationPhoto,
        ),
        id: widget.vehicle?.id,
      );
      if (mounted) setState(() => _saved = saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enregistrement impossible. Veuillez réessayer.'),
      ));
    }
  }

  Widget _reveal(int index, Widget child) {
    final start = index * 80 / 1100;
    final opacity = _entry.drive(CurveTween(
        curve:
            Interval(start, start + 700 / 1100, curve: Curves.easeOutCubic)));
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position:
            opacity.drive(Tween(begin: const Offset(0, .06), end: Offset.zero)),
        child: child,
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
          {bool year = false, String? hint}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _fieldLabel),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            enabled: !_busy,
            textInputAction: TextInputAction.next,
            keyboardType: year ? TextInputType.number : TextInputType.text,
            inputFormatters: year
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4)
                  ]
                : null,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (year) {
                final number = int.tryParse(text);
                return text.isNotEmpty &&
                        (number == null ||
                            number < 1900 ||
                            number > DateTime.now().year + 1)
                    ? 'Année invalide.'
                    : null;
              }
              return text.isEmpty ? 'Champ obligatoire.' : null;
            },
          ),
        ],
      );

  static const _fieldLabel =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

  Widget _plate() => FormField<String>(
        validator: (_) =>
            _serial.text.isEmpty || _letter == null || _region.text.isEmpty
                ? 'Complétez le numéro, la lettre et le code province.'
                : null,
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Immatriculation *',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            InputDecorator(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                errorMaxLines: 3,
                errorText: field.errorText,
              ),
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  Expanded(
                      flex: 2,
                      child: _platePart(_serial, 'Numéro', '12345', 5)),
                  const Text('|'),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: const ValueKey('plate-letter'),
                        isExpanded: true,
                        alignment: Alignment.center,
                        iconSize: 14,
                        hint: const Text('—', textAlign: TextAlign.center),
                        value: _letter,
                        items: [
                          for (final letter in {
                            ..._letters,
                            if (_letter != null) _letter!
                          })
                            DropdownMenuItem(
                                value: letter,
                                child: Center(child: Text(letter))),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _letter = value),
                      ),
                    ),
                  ),
                  const Text('|'),
                  Expanded(
                      child: _platePart(_region, 'Code province', '33', 2)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _platePart(TextEditingController controller, String label, String hint,
          int limit) =>
      Semantics(
        label: label,
        child: TextField(
          key: ValueKey(label),
          controller: controller,
          enabled: !_busy,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(limit)
          ],
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );

  Widget _places() => LayoutBuilder(
        builder: (context, constraints) {
          final selected = int.tryParse(_capacity.text);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nombre de places *',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 5,
                children: [
                  for (var count = 2; count <= 6; count++)
                    SizedBox(
                      width: math.min(46.0, (constraints.maxWidth - 32) / 5),
                      child: _PressScale(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(38, 44),
                            backgroundColor:
                                !_customCapacity && selected == count
                                    ? vehicleOlive
                                    : null,
                            foregroundColor:
                                !_customCapacity && selected == count
                                    ? vehicleCream
                                    : vehicleInk,
                            side: BorderSide(
                                color: !_customCapacity && selected == count
                                    ? vehicleOlive
                                    : vehicleTeal,
                                width: 1.5),
                            shape: const CircleBorder(),
                          ),
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _capacity.text = '$count';
                                    _customCapacity = false;
                                  }),
                          child: Text('$count'),
                        ),
                      ),
                    ),
                ],
              ),
              if (_customCapacity)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _capacity,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(labelText: 'Places passagers'),
                    validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                        ? 'Indiquez un nombre entier supérieur à zéro.'
                        : null,
                  ),
                )
              else
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _customCapacity = true),
                  child: const Text('Autre capacité'),
                ),
            ],
          );
        },
      );

  Widget _informationCard() => AnimatedBuilder(
        animation: _shake,
        builder: (context, child) => Transform.translate(
          offset: Offset(
              math.sin(_shake.value * math.pi * 4) * 6 * (1 - _shake.value), 0),
          child: child,
        ),
        child: _Section(
          key: _information,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final year = _field('Année', _year, year: true, hint: '2021');
              final plate = _plate();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _field('Marque *', _make, hint: 'Choisir')),
                    const SizedBox(width: 10),
                    Expanded(child: _field('Modèle *', _model, hint: 'Clio 4')),
                  ]),
                  const SizedBox(height: 10),
                  if (constraints.maxWidth >= 320)
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: year),
                          const SizedBox(width: 10),
                          Expanded(child: plate),
                        ])
                  else ...[
                    year,
                    const SizedBox(height: 10),
                    plate,
                  ],
                  const SizedBox(height: 10),
                  _field('Couleur *', _color),
                  const SizedBox(height: 12),
                  _places(),
                ],
              );
            },
          ),
        ),
      );

  Widget _registrationCard() {
    final photo = _registrationPhoto;
    final scanning = _pickingRegistration == true;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return _Section(
      child: AnimatedSwitcher(
        duration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 260),
        child: scanning
            ? const SizedBox(
                key: ValueKey('registration-scanning'),
                height: 110,
                width: double.infinity,
                child: VehicleScanFrame(),
              )
            : Column(
                key: const ValueKey('registration-actions'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined,
                          size: 24, color: vehicleInk),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Carte grise',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                            Text(
                              photo == null
                                  ? 'Photographiez le document'
                                  : 'Image ajoutée',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: vehicleInk.withValues(alpha: .72)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PressScale(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            textStyle: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontSize: 12),
                          ),
                          onPressed: _busy
                              ? null
                              : () =>
                                  _pick(ImageSource.camera, registration: true),
                          child: Text(photo == null ? 'Scanner' : 'Rescanner'),
                        ),
                      ),
                    ],
                  ),
                  if (photo != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 124,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VehicleImagePreview(
                              bytes: photo,
                              label: 'Carte grise',
                              expandable: true),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: _RoundButton(
                              tooltip: 'Retirer : Carte grise',
                              icon: Icons.delete_outline,
                              color: const Color(0xffa2402f),
                              action: _busy
                                  ? null
                                  : () =>
                                      setState(() => _registrationPhoto = null),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _PressScale(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                            textStyle: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontSize: 12)),
                        onPressed: _busy
                            ? null
                            : () =>
                                _pick(ImageSource.gallery, registration: true),
                        icon:
                            const Icon(Icons.photo_library_outlined, size: 17),
                        label: Text(photo == null
                            ? 'Choisir depuis la galerie'
                            : 'Remplacer depuis la galerie'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _vehiclePhotoCard() {
    final photo = _photo;
    final picking = _pickingRegistration == false;
    return _Section(
      title: 'Photo du véhicule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: photo == null ? 106 : 146,
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              child: switch (photo) {
                final image? => Stack(
                    key: ObjectKey(image),
                    fit: StackFit.expand,
                    children: [
                      VehicleImagePreview(
                          bytes: image,
                          label: 'Photo du véhicule',
                          fit: BoxFit.cover),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _RoundButton(
                          tooltip: 'Retirer : Photo du véhicule',
                          icon: Icons.delete_outline,
                          color: const Color(0xffa2402f),
                          action: _busy
                              ? null
                              : () => setState(() => _photo = null),
                        ),
                      ),
                    ],
                  ),
                null => VehicleDashedFrame(
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.photo_camera_outlined,
                            color: vehicleOlive),
                        const SizedBox(height: 6),
                        Text(picking
                            ? 'Préparation de l’image…'
                            : 'Ajoutez une photo claire'),
                      ]),
                    ),
                  ),
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _MediaButton(
              icon: Icons.photo_camera_outlined,
              label: 'Prendre une photo',
              filled: true,
              action: _busy
                  ? null
                  : () => _pick(ImageSource.camera, registration: false),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _MediaButton(
              icon: Icons.photo_library_outlined,
              label: 'Galerie',
              action: _busy
                  ? null
                  : () => _pick(ImageSource.gallery, registration: false),
            )),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.vehicle == null ? 'Ajouter un véhicule' : 'Modifier un véhicule';
    final saved = _saved;
    final heading = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(fontSize: 30, height: 1.02, letterSpacing: -1);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
                child: saved == null
                    ? Stack(
                        children: [
                          const Positioned(
                              top: -110,
                              right: -90,
                              child: _Halo(color: vehicleTeal)),
                          const Positioned(
                              bottom: -75,
                              left: -95,
                              child: _Halo(color: vehicleBlue)),
                          Column(
                            children: [
                              Expanded(
                                child: Form(
                                  key: _form,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                        18, 16, 18, 8),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _reveal(
                                              0,
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  _RoundButton(
                                                    tooltip: 'Retour',
                                                    icon: Icons.chevron_left,
                                                    action: _busy
                                                        ? null
                                                        : () => Navigator.pop(
                                                            context),
                                                  ),
                                                  Flexible(
                                                      child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: vehicleTeal),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 4),
                                                      child: Text(
                                                        widget.vehicle == null
                                                            ? 'Nouveau'
                                                            : 'Modification',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ),
                                                  )),
                                                ],
                                              )),
                                          const SizedBox(height: 14),
                                          _reveal(
                                              1, Text(title, style: heading)),
                                          const SizedBox(height: 14),
                                          _reveal(2, _registrationCard()),
                                          const SizedBox(height: 10),
                                          _reveal(3, _informationCard()),
                                          const SizedBox(height: 10),
                                          _reveal(4, _vehiclePhotoCard()),
                                        ]),
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Color(0x00eee7d7), vehicleCream],
                                      stops: [0, .55]),
                                ),
                                child: _PressScale(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                        minimumSize: const Size(0, 54)),
                                    onPressed: _busy ? null : _submit,
                                    child: _saving
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : Text(widget.vehicle == null
                                            ? 'Ajouter le véhicule'
                                            : 'Enregistrer'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const VehicleSaveCheck(),
                            const SizedBox(height: 14),
                            Text('Véhicule enregistré',
                                textAlign: TextAlign.center, style: heading),
                            const SizedBox(height: 8),
                            Text(saved.name, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            _PressScale(
                              child: FilledButton(
                                onPressed: () => Navigator.pop(context, saved),
                                child: const Text('Terminer'),
                              ),
                            ),
                          ]),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: vehicleBlue.withValues(alpha: .24),
          border: Border.all(color: vehicleBlue.withValues(alpha: .70)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: title == null
            ? child
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
      );
}

class _MediaButton extends StatelessWidget {
  const _MediaButton(
      {required this.icon,
      required this.label,
      this.action,
      this.filled = false});

  final IconData icon;
  final String label;
  final VoidCallback? action;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, 72),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: filled ? vehicleOlive : Colors.transparent,
      foregroundColor: filled ? vehicleCream : vehicleInk,
      side: filled ? null : const BorderSide(color: vehicleTeal, width: 1.5),
    );
    return _PressScale(
      child: FilledButton(
        onPressed: action,
        style: style,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton(
      {required this.tooltip,
      required this.icon,
      this.action,
      this.color = vehicleInk});

  final String tooltip;
  final IconData icon;
  final VoidCallback? action;
  final Color color;

  @override
  Widget build(BuildContext context) => _PressScale(
        child: IconButton(
          onPressed: action,
          tooltip: tooltip,
          style: IconButton.styleFrom(
              backgroundColor: vehicleCream,
              foregroundColor: color,
              side: const BorderSide(color: vehicleTeal, width: 1.5)),
          icon: Icon(icon),
        ),
      );
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});

  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 150),
          scale: _pressed ? .97 : 1,
          child: widget.child,
        ),
      );
}

class _Halo extends StatelessWidget {
  const _Halo({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox.square(
          dimension: 250,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                color.withValues(alpha: .52),
                color.withValues(alpha: 0)
              ]),
            ),
          ),
        ),
      );
}
