import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vehicles/domain/vehicle.dart';
import '../../../vehicles/presentation/vehicle_provider.dart';
import '../../../vehicles/presentation/vehicle_theme.dart';
import '../../../vehicles/presentation/vehicles_page.dart';
import '../../domain/entities/publish_trip.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';
import '../widgets/trip_publish_confirmation.dart';
import '../widgets/trip_publish_controls.dart';

class TripForm extends ConsumerStatefulWidget {
  const TripForm({super.key, required this.isPreview, this.tripToEdit});
  final bool isPreview;
  final Trip? tripToEdit;

  @override
  ConsumerState<TripForm> createState() => _TripFormState();
}

class _TripFormState extends ConsumerState<TripForm>
    with TickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  late final _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1260));
  late final _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 28));
  late DateTime _day = _tomorrow;
  int _minutes = 480;
  int _seats = 3;
  int _price = 15;
  double _turns = 0;
  String? _vehicleId;
  String? _error;
  bool _saving = false;
  bool _published = false;
  bool _validateDeparture = false;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());
  DateTime get _tomorrow => DateTime(_today.year, _today.month, _today.day + 1);
  DateTime get _departure =>
      DateTime(_day.year, _day.month, _day.day, _minutes ~/ 60, _minutes % 60);
  bool get _departureIsFuture => _departure.isAfter(DateTime.now());
  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    final details = widget.tripToEdit?.details;
    if (details == null) return;
    final departure = details.departureAt.toLocal();
    _origin.text = details.origin;
    _destination.text = details.destination;
    _day = DateUtils.dateOnly(departure);
    _minutes = departure.hour * 60 + departure.minute;
    _seats = details.seats;
    _price = details.contributionDh ?? 0;
    _vehicleId = details.vehicleId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotion) {
      _entrance.value = 1;
      _drift.stop();
    } else if (_entrance.value == 0 && !_entrance.isAnimating) {
      _entrance.forward();
    }
    if (!_reducedMotion && !_published && !_drift.isAnimating) _drift.repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _drift.dispose();
    _origin.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final today = _today;
    final next = await showDatePicker(
      context: context,
      firstDate: today,
      initialDate: _day.isBefore(today) ? today : _day,
      lastDate: DateTime(today.year + 10, today.month, today.day),
      helpText: 'Date du trajet',
      cancelText: 'Annuler',
      confirmText: 'Choisir',
    );
    if (mounted && next != null) _setDeparture(day: next);
  }

  void _setDeparture({DateTime? day, int? minutes}) {
    setState(() {
      if (day != null) _day = day;
      if (minutes != null) _minutes = minutes;
      _validateDeparture = true;
    });
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
      helpText: 'Heure de départ',
      cancelText: 'Annuler',
      confirmText: 'Choisir',
      hourLabelText: 'Heure',
      minuteLabelText: 'Minutes',
      errorInvalidText: 'Heure invalide',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (mounted && selected != null) {
      _setDeparture(minutes: selected.hour * 60 + selected.minute);
    }
  }

  void _swap() {
    final first = _origin.text;
    _origin.text = _destination.text;
    _destination.text = first;
    setState(() => _turns += .5);
  }

  Vehicle? _selected(List<Vehicle> items) {
    for (final item in items) {
      if (item.id == _vehicleId) return item;
    }
    return widget.tripToEdit == null ? items.firstOrNull : null;
  }

  Future<void> _chooseVehicle(List<Vehicle> items, Vehicle selected) async {
    final next = await showModalBottomSheet<Vehicle>(
      context: context,
      backgroundColor: vehicleCream,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            for (final item in items)
              ListTile(
                leading: const Icon(Icons.directions_car_outlined),
                title: Text(item.name),
                subtitle: Text(
                    '${item.details.registrationNumber} · ${item.details.passengerCapacity} places'),
                trailing:
                    item.id == selected.id ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      ),
    );
    if (!mounted || next == null) return;
    setState(() {
      _vehicleId = next.id;
      _seats = math.min(_seats, next.details.passengerCapacity);
    });
  }

  int _capacity(Vehicle? vehicle) =>
      vehicle?.details.passengerCapacity ??
      widget.tripToEdit?.details.seats ??
      0;

  Future<void> _saveTrip() async {
    if (_saving || _published) return;
    FocusScope.of(context).unfocus();
    final valid = _form.currentState?.validate() ?? false;
    final vehicle =
        _selected(ref.read(vehiclesProvider).valueOrNull ?? const []);
    final tripToEdit = widget.tripToEdit;
    final vehicleId = vehicle?.id ?? tripToEdit?.details.vehicleId;
    final capacity = _capacity(vehicle);
    final departure = _departure;
    if (!valid ||
        vehicleId == null ||
        capacity < 1 ||
        !departure.isAfter(DateTime.now())) {
      setState(() {
        _validateDeparture = true;
        _error = !valid
            ? 'Vérifiez le départ et la destination.'
            : vehicleId == null || capacity < 1
                ? 'Sélectionnez un véhicule disposant de places.'
                : null;
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    Trip? updatedTrip;
    try {
      final repository = ref.read(tripRepositoryProvider);
      final details = PublishTrip(
        origin: _origin.text.trim(),
        destination: _destination.text.trim(),
        departureAt: departure,
        vehicleId: vehicleId,
        seats: math.min(_seats, capacity),
        contributionDh: _price == 0 ? null : _price,
      );
      if (tripToEdit != null) {
        updatedTrip = await repository.update(tripToEdit.id, details);
      } else {
        await repository.publish(details);
        if (mounted) {
          _drift.stop();
          setState(() => _published = true);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = tripToEdit == null
            ? 'Publication impossible. Réessayez.'
            : 'Modification impossible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted && updatedTrip != null) Navigator.of(context).pop(updatedTrip);
  }

  void _finish() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    _origin.clear();
    _destination.clear();
    setState(() {
      _published = false;
      _validateDeparture = false;
      _day = _tomorrow;
      _minutes = 480;
      _seats = 3;
      _price = 15;
      _turns = 0;
      _vehicleId = null;
    });
    if (!_reducedMotion) {
      _entrance.forward(from: 0);
      _drift.repeat();
    }
  }

  Widget _reveal(int index, Widget child) {
    final start = index * 80 / 1260;
    final animation = _entrance.drive(CurveTween(
      curve: Interval(start, start + 700 / 1260, curve: Curves.easeOutCubic),
    ));
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, 16 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }

  Widget _placeField(
          TextEditingController controller, String label, String hint,
          {required bool origin}) =>
      Row(children: [
        Icon(origin ? Icons.radio_button_unchecked : Icons.circle,
            size: 11, color: vehicleOlive),
        const SizedBox(width: 8),
        Expanded(
            child: Semantics(
          label: label,
          child: TextFormField(
            key: ValueKey(label),
            controller: controller,
            enabled: !_saving,
            textInputAction:
                origin ? TextInputAction.next : TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: vehicleInk.withValues(alpha: .64)),
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
            validator: (value) {
              final location = value?.trim() ?? '';
              if (location.isEmpty) return '$label obligatoire';
              if (!origin &&
                  location.toLowerCase() == _origin.text.trim().toLowerCase()) {
                return 'Choisissez une autre destination';
              }
              return null;
            },
          ),
        )),
      ]);

  Widget _routeCard() => TripOliveCard(
        child: Row(children: [
          Expanded(
              child: Column(children: [
            _placeField(_origin, 'Départ', 'Gare Marrakech', origin: true),
            const SizedBox(height: 3),
            _placeField(_destination, 'Destination', 'Campus universitaire',
                origin: false),
          ])),
          const SizedBox(width: 10),
          TripCircleButton(
            tooltip: 'Inverser les lieux',
            onPressed: _saving ? null : _swap,
            child: AnimatedRotation(
              turns: _turns,
              duration: _reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              child: const Icon(Icons.swap_vert_rounded, size: 19),
            ),
          ),
        ]),
      );

  Widget _vehicleCard(AsyncValue<List<Vehicle>> vehicles, Vehicle? selected) {
    if (selected != null) {
      return TripOliveCard(
        onTap: _saving || widget.tripToEdit != null
            ? null
            : () => _chooseVehicle(vehicles.valueOrNull ?? [], selected),
        child: Row(children: [
          const SizedBox(width: 64, height: 36, child: TripVehicleDrawing()),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const TripNote('Véhicule utilisé'),
                Text(selected.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                TripNote(
                    '${selected.details.registrationNumber} · ${selected.details.passengerCapacity} places'),
              ])),
          if (widget.tripToEdit == null) ...[
            const SizedBox(width: 8),
            const TripNote('Changer ⇄'),
          ],
        ]),
      );
    }
    if (vehicles.isLoading) {
      return const TripOliveCard(child: TripNote('Chargement des véhicules…'));
    }
    if (vehicles.hasError) {
      return TripOliveCard(
        child: Row(children: [
          const Expanded(child: Text('Véhicules indisponibles')),
          TextButton(
              onPressed: () => ref.invalidate(vehiclesProvider),
              child: const Text('Réessayer')),
        ]),
      );
    }
    if (widget.tripToEdit != null) {
      return const TripOliveCard(child: TripNote('Véhicule indisponible'));
    }
    return TripOliveCard(
      child: Row(children: [
        const Expanded(child: Text('Aucun véhicule disponible')),
        if (widget.isPreview)
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const VehiclesPage(isDemo: true),
            )),
            child: const Text('Ajouter'),
          ),
      ]),
    );
  }

  Widget _dayControl() {
    final today = DateUtils.isSameDay(_day, _today);
    final tomorrow = DateUtils.isSameDay(_day, _tomorrow);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          const TripNote('Heure de départ'),
          Row(mainAxisSize: MainAxisSize.min, children: [
            TripDaySegment(
              selected: today
                  ? 0
                  : tomorrow
                      ? 1
                      : null,
              onSelected: (index) {
                if (!_saving) {
                  _setDeparture(day: index == 0 ? _today : _tomorrow);
                }
              },
            ),
            const SizedBox(width: 6),
            TripCircleButton(
              tooltip: 'Choisir une date',
              onPressed: _saving ? null : _pickDay,
              child: const Icon(Icons.calendar_today_outlined, size: 16),
            ),
          ]),
        ],
      ),
      if (!today && !tomorrow)
        Align(
          alignment: Alignment.centerRight,
          child: TripNote(
              MaterialLocalizations.of(context).formatCompactDate(_day)),
        ),
    ]);
  }

  Widget _timeControl() {
    final time =
        '${(_minutes ~/ 60).toString().padLeft(2, '0')}:${(_minutes % 60).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          TripCircleButton(
            tooltip: 'Retirer 15 minutes',
            onPressed: _saving
                ? null
                : () => _setDeparture(minutes: (_minutes - 15) % 1440),
            child: const Text('−', style: TextStyle(fontSize: 20)),
          ),
          Expanded(
            child: Tooltip(
              message: 'Choisir l’heure',
              child: InkWell(
                onTap: _saving ? null : _pickTime,
                borderRadius: BorderRadius.circular(22),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedSwitcher(
                    duration: _reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(Tween(
                            begin: const Offset(0, -.18), end: Offset.zero)),
                        child: child,
                      ),
                    ),
                    child: Text(
                      time,
                      key: ValueKey(time),
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontSize: 76, height: 1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          TripCircleButton(
            tooltip: 'Ajouter 15 minutes',
            onPressed: _saving
                ? null
                : () => _setDeparture(minutes: (_minutes + 15) % 1440),
            child: const Text('+', style: TextStyle(fontSize: 20)),
          ),
        ]),
        if (_validateDeparture && !_departureIsFuture)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Choisissez une date et une heure de départ futures.',
              style: TextStyle(color: Color(0xffa2402f), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _moreSeats(int capacity, int seats) async {
    final next = await showDialog<int>(
      context: context,
      builder: (_) => _SeatDialog(capacity: capacity, seats: seats),
    );
    if (mounted && next != null) setState(() => _seats = next);
  }

  Widget _seatControl(int capacity, int seats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TripNote('Places disponibles'),
          const SizedBox(height: 8),
          if (capacity < 1)
            const TripNote('Sélectionnez un véhicule')
          else
            Wrap(spacing: 10, runSpacing: 8, children: [
              for (var i = 1; i <= math.min(capacity, 7); i++)
                TripSeat(
                  count: i,
                  filled: i <= seats,
                  selected: i == seats,
                  onPressed: _saving ? null : () => setState(() => _seats = i),
                ),
              if (capacity > 7)
                TripCircleButton(
                  tooltip: 'Choisir un autre nombre de places',
                  onPressed: _saving ? null : () => _moreSeats(capacity, seats),
                  child: Text(seats > 7 ? '$seats' : '+',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ]),
        ],
      );

  Widget _contributionControl(int seats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Flexible(child: TripNote('Contribution / passager')),
            Text(_price == 0 ? 'Gratuit' : '$_price DH',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              trackShape: const RoundedRectSliderTrackShape(),
              tickMarkShape: SliderTickMarkShape.noTickMark,
              activeTrackColor: vehicleTeal,
              inactiveTrackColor: vehicleTeal,
              thumbColor: vehicleOlive,
              thumbShape: const TripSliderThumb(),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 17),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              min: 0,
              max: 40,
              divisions: 40,
              value: _price.toDouble(),
              semanticFormatterCallback: (value) =>
                  '${value.round()} DH par passager',
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _price = value.round()),
            ),
          ),
          TripNote('Jusqu’à ${seats * _price} DH pour ce trajet'),
        ],
      );

  Widget _halo(Color color, double phase) => AnimatedBuilder(
        animation: _drift,
        child: TripHalo(color: color),
        builder: (_, child) {
          final value = Curves.easeInOut.transform(
            (1 - (2 * ((_drift.value + phase) % 1) - 1).abs()),
          );
          return Transform.translate(
            offset: Offset(-30 * value, 40 * value),
            child: Transform.scale(scale: 1 + .15 * value, child: child),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider);
    final selected = _selected(vehicles.valueOrNull ?? const []);
    final capacity = _capacity(selected);
    final editing = widget.tripToEdit != null;
    final seats = math.min(_seats, math.max(0, capacity));
    return PopScope(
      canPop: !_saving,
      child: AnimatedSwitcher(
        duration:
            _reducedMotion ? Duration.zero : const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(Tween(begin: .97, end: 1.0)),
            child: child,
          ),
        ),
        child: _published
            ? TripPublishConfirmation(
                isPreview: widget.isPreview, onDone: _finish)
            : Stack(fit: StackFit.expand, children: [
                Positioned(top: -70, right: -60, child: _halo(vehicleTeal, 0)),
                Positioned(
                    bottom: 60, left: -80, child: _halo(vehicleBlue, .22)),
                Form(
                  key: _form,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _reveal(
                              0,
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TripNote(widget.isPreview
                                        ? 'Aperçu local'
                                        : 'Publication'),
                                    TripPill(
                                        editing ? 'Modification' : 'Brouillon'),
                                  ])),
                          const SizedBox(height: 12),
                          _reveal(
                              1,
                              Text(
                                  editing
                                      ? 'Modifier le trajet'
                                      : 'Où tu vas ?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontSize: 30,
                                        height: 1,
                                        letterSpacing: -1.2,
                                      ))),
                          const SizedBox(height: 14),
                          _reveal(2, _routeCard()),
                          const SizedBox(height: 6),
                          _reveal(
                              2, const TripNote('Distance et durée à estimer')),
                          const SizedBox(height: 12),
                          _reveal(3, _dayControl()),
                          const SizedBox(height: 4),
                          _reveal(4, _timeControl()),
                          const SizedBox(height: 12),
                          _reveal(5, _seatControl(capacity, seats)),
                          const SizedBox(height: 18),
                          _reveal(6, _contributionControl(seats)),
                          const SizedBox(height: 12),
                          _reveal(6, _vehicleCard(vehicles, selected)),
                          if (_error case final error?) ...[
                            const SizedBox(height: 10),
                            Text(error,
                                style:
                                    const TextStyle(color: Color(0xffa2402f))),
                          ],
                          const SizedBox(height: 12),
                          _reveal(
                              7,
                              TripPress(
                                child: FilledButton(
                                  onPressed: _saving ? null : _saveTrip,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 16),
                                  ),
                                  child: Text(
                                      editing
                                          ? (_saving
                                              ? 'Enregistrement…'
                                              : 'Enregistrer les modifications')
                                          : (_saving
                                              ? 'Publication…'
                                              : 'Publier le trajet'),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                ),
                              )),
                        ]),
                  ),
                ),
              ]),
      ),
    );
  }
}

class _SeatDialog extends StatefulWidget {
  const _SeatDialog({required this.capacity, required this.seats});
  final int capacity;
  final int seats;

  @override
  State<_SeatDialog> createState() => _SeatDialogState();
}

class _SeatDialogState extends State<_SeatDialog> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: '${widget.seats}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Places disponibles'),
        content: Form(
          key: _form,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            validator: (value) {
              final seats = int.tryParse(value?.trim() ?? '');
              return seats == null || seats < 1 || seats > widget.capacity
                  ? 'Choisissez de 1 à ${widget.capacity} places.'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (_form.currentState!.validate()) {
                Navigator.pop(context, int.parse(_controller.text.trim()));
              }
            },
            child: const Text('Choisir'),
          ),
        ],
      );
}
