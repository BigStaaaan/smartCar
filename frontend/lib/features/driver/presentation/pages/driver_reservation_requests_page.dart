import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../vehicles/presentation/vehicle_theme.dart';
import '../../data/driver_reservation_repository.dart';
import '../widgets/driver_avatar.dart';

class DriverReservationRequestsPage extends StatelessWidget {
  const DriverReservationRequestsPage({
    super.key,
    required this.repository,
    this.isPreview = false,
  });

  final DriverReservationRepository repository;
  final bool isPreview;

  @override
  Widget build(BuildContext context) => Theme(
        data: driverTheme(),
        child: _RequestsScreen(repository: repository, isPreview: isPreview),
      );
}

class _RequestsScreen extends StatefulWidget {
  const _RequestsScreen({required this.repository, required this.isPreview});

  final DriverReservationRepository repository;
  final bool isPreview;

  @override
  State<_RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<_RequestsScreen> {
  List<DriverReservationRequest> _pending = [];
  bool _loading = true;
  bool _loadFailed = false;
  bool _processing = false;
  bool _dragging = false;
  bool _leaving = false;
  double _offset = 0;
  String? _message;

  static const _swipeThreshold = 90.0;
  static const _exitDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final pending = await widget.repository.listPending();
      if (mounted) setState(() => _pending = pending);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetDrag() {
    setState(() {
      _offset = 0;
      _dragging = false;
    });
  }

  void _finishDrag() {
    if (_processing) return;
    if (_offset.abs() < _swipeThreshold) {
      _resetDrag();
      return;
    }
    _decide(accept: _offset > 0);
  }

  Future<void> _decide({required bool accept}) async {
    if (_processing || _pending.isEmpty) return;
    final request = _pending.first;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final exitDistance = MediaQuery.sizeOf(context).width + 120;
    setState(() {
      _processing = true;
      _dragging = false;
      _message = null;
      if (!accept) _offset = 0;
    });

    try {
      if (!accept) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Refuser cette demande ?'),
            content: Text('Demande de ${request.passengerName}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Retour'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmer le refus'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
      }

      await widget.repository.decide(
        request.id,
        accept
            ? DriverReservationStatus.accepted
            : DriverReservationStatus.rejected,
      );
      if (!mounted) return;
      setState(() {
        _leaving = true;
        _offset = accept ? exitDistance : -exitDistance;
      });
      if (!reducedMotion) await Future<void>.delayed(_exitDuration);
      if (!mounted) return;
      setState(() {
        _pending = _pending.where((item) => item.id != request.id).toList();
        _message = accept
            ? '${request.passengerName} · demande acceptée ✓'
            : '${request.passengerName} · demande refusée';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Action impossible. Réessayez.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _leaving = false;
          _offset = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: driverSurface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  driverPageMargin, 24, driverPageMargin, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        BackButton(color: driverText),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Demandes',
                                style:
                                    Theme.of(context).textTheme.displayLarge),
                          ),
                        ),
                      ),
                      if (!_loading && !_loadFailed)
                        _RequestBadge(_pending.isEmpty
                            ? 'Tout est traité'
                            : '${_pending.length} à traiter'),
                    ],
                  ),
                  if (widget.isPreview)
                    const Text('Aperçu local · données de démonstration'),
                  const SizedBox(height: 6),
                  if (_pending.isNotEmpty)
                    Text('Glisse à droite pour accepter, à gauche pour refuser',
                        style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 18),
                  if (_loading || _loadFailed || _pending.isEmpty)
                    SizedBox(
                      height: 330,
                      child: Center(child: _placeholder(context)),
                    )
                  else ...[
                    _buildStack(reduced),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _processing ? null : _showDetails,
                        child: const Text('Voir les détails'),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _actionButton(accept: false),
                        const SizedBox(width: 34),
                        _actionButton(accept: true),
                      ],
                    ),
                  ],
                  if (_message case final message?) ...[
                    const SizedBox(height: 14),
                    Semantics(
                      liveRegion: true,
                      child: Text(message, textAlign: TextAlign.center),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails() {
    final request = _pending.first;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      useSafeArea: true,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            driverPageMargin, 0, driverPageMargin, driverSectionGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Fermer les détails',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            _RequestCard(request: request, offset: 0, showFullDetails: true),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    if (_loading) return const CircularProgressIndicator();
    if (_loadFailed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Demandes indisponibles'),
          TextButton(onPressed: _load, child: const Text('Réessayer')),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Tout est traité',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        const Text('Aucune demande en attente'),
      ],
    );
  }

  Widget _buildStack(bool reduced) {
    final lastIndex = math.min(_pending.length, 3) - 1;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
            offset: Offset(0, 16 * (1 - progress)), child: child),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          for (var index = lastIndex; index >= 0; index--)
            if (index == 0)
              ConstrainedBox(
                key: ValueKey(_pending.first.id),
                constraints: const BoxConstraints(minHeight: 330),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _processing
                      ? null
                      : (_) => setState(() => _dragging = true),
                  onHorizontalDragUpdate: _processing
                      ? null
                      : (event) => setState(() => _offset += event.delta.dx),
                  onHorizontalDragEnd:
                      _processing ? null : (_) => _finishDrag(),
                  onHorizontalDragCancel: _processing ? null : _resetDrag,
                  child: AnimatedContainer(
                    duration:
                        reduced || _dragging ? Duration.zero : _exitDuration,
                    curve: Curves.easeOutCubic,
                    transformAlignment: Alignment.center,
                    transform: Matrix4.translationValues(_offset, 0, 0)
                      ..rotateZ((_offset / 920).clamp(-.42, .42).toDouble()),
                    child: AnimatedOpacity(
                      duration: reduced ? Duration.zero : _exitDuration,
                      opacity: _leaving ? 0 : 1,
                      child: _RequestCard(
                          request: _pending.first, offset: _offset),
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                key: ValueKey(_pending[index].id),
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(0, index * 14.0),
                      child: Transform.scale(
                        scale: 1 - index * .05,
                        child: const _CardSurface(),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _actionButton({required bool accept}) => IconButton(
        onPressed: _processing ? null : () => _decide(accept: accept),
        tooltip: accept ? 'Accepter la demande' : 'Refuser la demande',
        style: IconButton.styleFrom(
          fixedSize: const Size.square(58),
          backgroundColor:
              accept ? AppColors.secondary : AppColors.surfaceContainerLowest,
          foregroundColor: accept ? driverOnAccent : driverText,
          side: BorderSide(color: accept ? AppColors.secondary : driverOutline),
        ),
        icon: Icon(accept ? Icons.check : Icons.close, size: 23),
      );
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard(
      {required this.request,
      required this.offset,
      this.showFullDetails = false});

  final DriverReservationRequest request;
  final double offset;
  final bool showFullDetails;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final departure = request.departureAt.toLocal();
    final date = localizations.formatCompactDate(departure);
    final time = localizations.formatTimeOfDay(
        TimeOfDay.fromDateTime(departure),
        alwaysUse24HourFormat: true);
    final contribution = request.contributionDh;
    final name = request.passengerName.trim();
    final rating = request.rating;
    return _CardSurface(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DriverAvatar(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  photoUrl: request.photoUrl,
                  size: 64,
                  fontSize: 24,
                  background: AppColors.primaryFixed,
                ),
                const SizedBox(height: 10),
                Text(name,
                    maxLines: showFullDetails ? null : 2,
                    overflow: showFullDetails ? null : TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                if (rating != null)
                  Text('★ ${rating.toStringAsFixed(1).replaceAll('.', ',')}',
                      style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _RequestField('Prise en charge', request.pickup,
                            showFullDetails: showFullDetails)),
                    const SizedBox(width: 14),
                    Expanded(child: _RequestField('Départ', '$date · $time')),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _RequestField('Places', '${request.seats}')),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _RequestField(
                        'Contribution',
                        contribution == null
                            ? 'Non renseignée'
                            : contribution == 0
                                ? 'Gratuit'
                                : '$contribution DH',
                      ),
                    ),
                  ],
                ),
                if (request.isUniversityVerified) ...[
                  const SizedBox(height: 16),
                  const _RequestBadge('Compte universitaire vérifié',
                      verified: true),
                ],
              ],
            ),
          ),
          if (offset != 0)
            Positioned(
              left: offset > 0 ? 18 : null,
              right: offset < 0 ? 18 : null,
              top: 18,
              child: Opacity(
                opacity: (offset.abs() / 90).clamp(0, 1).toDouble(),
                child: Transform.rotate(
                  angle: offset > 0 ? -.17 : .17,
                  child: _RequestBadge(
                    offset > 0 ? 'OUI' : 'NON',
                    color: offset > 0 ? driverAccent : driverError,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestField extends StatelessWidget {
  const _RequestField(this.label, this.value, {this.showFullDetails = false});

  final bool showFullDetails;

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(value,
              maxLines: showFullDetails ? null : 2,
              overflow: showFullDetails ? null : TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge),
        ],
      );
}

class _RequestBadge extends StatelessWidget {
  const _RequestBadge(this.label,
      {this.color = driverAccent, this.verified = false});

  final String label;
  final Color color;
  final bool verified;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color == driverAccent
              ? AppColors.primaryFixed
              : AppColors.errorContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: color == driverAccent ? driverHighlight : color),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (verified)
              const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.check, size: 14, color: driverAccent)),
            Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: color))),
          ]),
        ),
      );
}
