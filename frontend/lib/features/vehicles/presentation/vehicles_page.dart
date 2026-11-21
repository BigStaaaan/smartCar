import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/vehicle.dart';
import 'vehicle_form_page.dart';
import 'vehicle_images.dart';
import 'vehicle_provider.dart';
import 'vehicle_theme.dart';

class VehiclesPage extends ConsumerWidget {
  const VehiclesPage({super.key, this.isDemo = false});

  final bool isDemo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);
    return Theme(
      data: vehicleTheme(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Mode Driver')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mes véhicules',
                              style: Theme.of(context).textTheme.displaySmall),
                          if (isDemo)
                            const Text('Démonstration · données temporaires'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        child: vehicles.when(
                          loading: () => const Center(
                            key: ValueKey('loading'),
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Chargement des véhicules',
                            ),
                          ),
                          error: (error, stackTrace) => _ListMessage(
                            key: const ValueKey('error'),
                            icon: Icons.cloud_off_outlined,
                            title: 'Impossible de charger vos véhicules',
                            action: TextButton(
                              onPressed: () => ref.invalidate(vehiclesProvider),
                              child: const Text('Réessayer'),
                            ),
                          ),
                          data: (items) => items.isEmpty
                              ? const _ListMessage(
                                  key: ValueKey('empty'),
                                  icon: Icons.directions_car_outlined,
                                  title: 'Aucun véhicule',
                                  description:
                                      'Ajoutez un véhicule pour préparer votre prochain trajet.',
                                )
                              : ListView.separated(
                                  key: const ValueKey('vehicles'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  itemCount: items.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final vehicle = items[index];
                                    return _VehicleCard(
                                      vehicle: vehicle,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              InheritedTheme.captureAll(
                                            context,
                                            _VehicleDetailsPage(
                                                vehicle: vehicle),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                    if (vehicles.hasValue)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                        child: FilledButton.icon(
                          onPressed: () => _openForm(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Ajouter un véhicule'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<Vehicle?> _openForm(BuildContext context, {Vehicle? vehicle}) =>
    Navigator.of(context).push<Vehicle>(
      MaterialPageRoute(
        builder: (_) => InheritedTheme.captureAll(
          context,
          VehicleFormPage(vehicle: vehicle),
        ),
      ),
    );

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, this.onTap});

  final Vehicle vehicle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: vehicleBlue.withValues(alpha: .24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: vehicleBlue),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: onTap,
          leading: switch (onTap == null ? null : vehicle.details.photo) {
            final photo? => SizedBox.square(
                dimension: 48,
                child: VehicleImagePreview(
                  bytes: photo,
                  label: 'Photo du véhicule',
                  fit: BoxFit.cover,
                ),
              ),
            null => const CircleAvatar(
                backgroundColor: vehicleTeal,
                foregroundColor: vehicleInk,
                child: Icon(Icons.directions_car_outlined),
              ),
          },
          title:
              Text(vehicle.name, style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text(vehicle.details.registrationNumber),
          trailing:
              onTap == null ? null : const Icon(Icons.chevron_right_rounded),
        ),
      );
}

class _ListMessage extends StatelessWidget {
  const _ListMessage({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: vehicleOlive, size: 42),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              if (description case final description?) ...[
                const SizedBox(height: 6),
                Text(description, textAlign: TextAlign.center),
              ],
              if (action case final action?) action,
            ],
          ),
        ),
      );
}

class _VehicleDetailsPage extends ConsumerStatefulWidget {
  const _VehicleDetailsPage({required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<_VehicleDetailsPage> createState() =>
      _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends ConsumerState<_VehicleDetailsPage> {
  late Vehicle _vehicle = widget.vehicle;
  bool _deleting = false;

  Future<void> _edit() async {
    final updated = await _openForm(context, vehicle: _vehicle);
    if (mounted && updated != null) setState(() => _vehicle = updated);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: Text('${_vehicle.name} sera retiré de la liste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await ref.read(vehiclesProvider.notifier).delete(_vehicle.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Suppression impossible. Veuillez réessayer.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _vehicle.details;
    final seats = details.passengerCapacity;
    return PopScope(
      canPop: !_deleting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Détail du véhicule')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (details.photo case final photo?) ...[
                    SizedBox(
                      height: 180,
                      child: VehicleImagePreview(
                        bytes: photo,
                        label: 'Photo du véhicule',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _VehicleCard(vehicle: _vehicle),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Couleur'),
                    subtitle: Text(details.color),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_seat_outlined),
                    title: const Text('Capacité passagers'),
                    subtitle: Text(seats == 1 ? '1 place' : '$seats places'),
                  ),
                  if (details.registrationPhoto case final registration?) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text('Carte grise',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    SizedBox(
                      height: 148,
                      child: VehicleImagePreview(
                        bytes: registration,
                        label: 'Carte grise',
                        expandable: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _deleting ? null : _edit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _deleting ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(_deleting ? 'Suppression…' : 'Supprimer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
