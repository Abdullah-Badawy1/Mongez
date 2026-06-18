import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/app_colors.dart';
import 'package:mongez/features/orders/data/models/order_attachment_model.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/features/orders/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/screens/rate_order_screen.dart';
import 'package:mongez/features/orders/presentation/widgets/status_badge.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;
  final bool isCustomer;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.isCustomer,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderModel _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final photos = _order.attachments.where((a) => a.isImage).toList();
    final audios = _order.attachments.where((a) => a.isAudio).toList();

    return Scaffold(
      appBar: CustomAppBar(title: lang.requestDetails),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Main info card ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _order.categoryName ?? 'Order #${_order.id}',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '#${_order.id}',
                              style: textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: _order.status, isCustomer: widget.isCustomer),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _UrgencyPill(urgency: _order.urgency, locale: locale),
                      if (_order.scheduledFor != null)
                        _MetaPill(
                          icon: Icons.schedule_outlined,
                          label: 'Scheduled · ${_formatDate(_order.scheduledFor)}',
                          color: cs.primary,
                        ),
                    ],
                  ),
                  if (_order.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _order.description,
                      style: textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _infoRow(Icons.calendar_today_outlined, _formatDate(_order.createdAt)),
                  if (_order.acceptedAt != null)
                    _infoRow(Icons.check_circle_outline,
                        'Accepted: ${_formatDate(_order.acceptedAt)}'),
                  if (_order.completedAt != null)
                    _infoRow(Icons.task_alt,
                        'Completed: ${_formatDate(_order.completedAt)}'),
                  const SizedBox(height: 16),
                  _ContactCard(
                    order: _order,
                    isCustomer: widget.isCustomer,
                    onCopy: (label, value) => _copyToClipboard(context, label, value),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailsActions(context),
                ],
              ),
            ),

            // ─── Attachments: photos ───────────────────────────────────
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              _AttachmentsHeader(
                icon: Icons.photo_library_outlined,
                title: 'Photos (${photos.length})',
              ),
              const SizedBox(height: 10),
              _PhotoGallery(photos: photos),
            ],

            // ─── Attachments: voice notes ──────────────────────────────
            if (audios.isNotEmpty) ...[
              const SizedBox(height: 16),
              _AttachmentsHeader(
                icon: Icons.mic_none_outlined,
                title: 'Voice notes (${audios.length})',
              ),
              const SizedBox(height: 10),
              ...audios.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AudioTile(attachment: a),
                  )),
            ],
            if (widget.isCustomer && _order.status == OrderStatus.waitingConfirmation) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.purple, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            S.of(context).workerMarkedFinished,
                            style: TextStyle(color: Colors.purple.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _doConfirmCompletion(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(S.of(context).confirmCompletion),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.isCustomer && _order.status == OrderStatus.completed) ...[
              const SizedBox(height: 16),
              if (_order.isRated)
                _buildRatedBanner(context)
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToRateOrder(context),
                    icon: const Icon(Icons.star_half),
                    label: Text(S.of(context).rateOrder),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    String label,
    String value,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildDetailsActions(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    if (widget.isCustomer) {
      if (_order.status == OrderStatus.pending) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showCancelDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(lang.cancel),
          ),
        );
      }
      if (_order.status == OrderStatus.accepted) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_order.workerName ?? lang.serviceProvider} accepted your request',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
            ],
          ),
        );
      }
      if (_order.status == OrderStatus.waitingConfirmation) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lang.workerMarkedFinished,
                  style: TextStyle(color: Colors.purple.shade700),
                ),
              ),
            ],
          ),
        );
      }
      if (_order.status == OrderStatus.completed) {
        return Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text(lang.completed, style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
          ],
        );
      }
      if (_order.status == OrderStatus.rejected) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lang.rejectedByWorker,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        );
      }
      if (_order.status == OrderStatus.cancelled) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lang.cancelledByYou,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      if (_order.status == OrderStatus.pending) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<TechnicianOrdersCubit>().acceptOrder(_order.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(lang.accept),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<TechnicianOrdersCubit>().rejectOrder(_order.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(lang.cancel),
              ),
            ),
          ],
        );
      }
      if (_order.status == OrderStatus.accepted) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Service is in progress',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<TechnicianOrdersCubit>().markAsFinished(_order.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(lang.markAsFinished),
              ),
            ),
          ],
        );
      }
      if (_order.status == OrderStatus.waitingConfirmation) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lang.waitingConfirmation,
                  style: TextStyle(color: Colors.purple.shade700),
                ),
              ),
            ],
          ),
        );
      }
    }

    return const SizedBox();
  }

  void _showCancelDialog(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.cancelRequest),
        content: Text(lang.cancelRequestConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CustomerOrdersCubit>().cancelOrder(_order.id);
              Navigator.pop(context);
            },
            child: Text(lang.yes, style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildRatedBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).ratingSubmitted,
              style: TextStyle(color: Colors.green.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doConfirmCompletion(BuildContext context) async {
    await context.read<CustomerOrdersCubit>().confirmCompletion(_order.id);
    if (mounted) {
      setState(() => _order = _order.copyWith(status: OrderStatus.completed));
    }
  }

  Future<void> _navigateToRateOrder(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RateOrderScreen(order: _order),
      ),
    );
    if (result == true && mounted) {
      setState(() => _order = _order.copyWith(isRated: true));
      context.read<CustomerOrdersCubit>().getOrders();
    }
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final OrderModel order;
  final bool isCustomer;
  final void Function(String label, String value) onCopy;

  const _ContactCard({
    required this.order,
    required this.isCustomer,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lang = S.of(context);

    // When the worker is viewing, show client info. When the client is
    // viewing, show worker info. The card is identical in shape.
    final isWorkerView = !isCustomer;
    final name = isWorkerView ? order.clientName : order.workerName;
    final phone = isWorkerView ? order.clientPhone : order.workerPhone;
    final avatar = isWorkerView ? order.clientImage : order.workerImage;
    final heading = isWorkerView ? lang.customer : lang.serviceProvider;

    // For a worker, location is essential — make it the visual anchor.
    final hasLocation = order.latitude != null && order.longitude != null;
    final hasAddress = order.address.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                backgroundImage: (avatar != null && avatar.isNotEmpty)
                    ? NetworkImage(avatar)
                    : null,
                child: (avatar == null || avatar.isEmpty)
                    ? Icon(Icons.person, color: cs.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name ?? '—',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TappableRow(
              icon: Icons.phone_outlined,
              label: phone,
              hint: 'Tap to copy',
              onTap: () => onCopy('Phone', phone),
            ),
          ],
          if (hasAddress) ...[
            const SizedBox(height: 8),
            _TappableRow(
              icon: Icons.location_on_outlined,
              label: order.address,
              hint: 'Tap to copy',
              onTap: () => onCopy('Address', order.address),
            ),
          ],
          if (hasLocation) ...[
            const SizedBox(height: 8),
            _TappableRow(
              icon: Icons.map_outlined,
              label:
                  '${order.latitude!.toStringAsFixed(5)}, ${order.longitude!.toStringAsFixed(5)}',
              hint: 'Tap to copy Google Maps link',
              onTap: () => onCopy(
                'Maps link',
                'https://www.google.com/maps?q=${order.latitude},${order.longitude}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TappableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;

  const _TappableRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (hint != null)
                    Text(
                      hint!,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.copy_rounded,
                size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _UrgencyPill extends StatelessWidget {
  final OrderUrgency urgency;
  final String locale;
  const _UrgencyPill({required this.urgency, required this.locale});
  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (urgency) {
      case OrderUrgency.low:
        color = AppColors.success;
        icon = Icons.schedule;
        break;
      case OrderUrgency.high:
        color = AppColors.danger;
        icon = Icons.local_fire_department_outlined;
        break;
      case OrderUrgency.normal:
        color = AppColors.primary;
        icon = Icons.today_outlined;
        break;
    }
    final label = locale == 'ar' ? urgency.labelAr : urgency.label;
    return _MetaPill(icon: icon, label: label, color: color);
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaPill({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentsHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _AttachmentsHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  final List<OrderAttachmentModel> photos;
  const _PhotoGallery({required this.photos});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final p = photos[i];
          return GestureDetector(
            onTap: p.fileUrl == null
                ? null
                : () => _openFullScreen(context, p.fileUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 110, height: 110,
                color: cs.surfaceContainerHighest,
                child: p.fileUrl == null
                    ? Icon(Icons.broken_image, color: cs.onSurface.withValues(alpha: 0.4))
                    : Image.network(
                        p.fileUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFullScreen(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white54, size: 64)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioTile extends StatefulWidget {
  final OrderAttachmentModel attachment;
  const _AudioTile({required this.attachment});
  @override
  State<_AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends State<_AudioTile> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final url = widget.attachment.fileUrl;
    if (url == null) return;
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(UrlSource(url));
      setState(() => _isPlaying = true);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final total = _total.inMilliseconds > 0
        ? _total
        : Duration(seconds: widget.attachment.durationSeconds ?? 0);
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary, shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.attachment.caption?.isNotEmpty == true
                      ? widget.attachment.caption!
                      : 'Voice note',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: cs.outline.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(_position)} / ${_fmt(total)}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
