import 'package:flutter/material.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/services/api_service.dart';
import 'package:mongez/services/services_locator.dart';
import 'package:mongez/widgets/custom_app_bar.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';

class RateOrderScreen extends StatefulWidget {
  final OrderModel order;

  const RateOrderScreen({super.key, required this.order});

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  int _stars = 0;
  final _reviewController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) return;
    setState(() => _submitting = true);
    try {
      await getIt.get<ApiService>().post(endPoint: Endpoints.ratings, body: {
        'order': widget.order.id,
        'stars': _stars,
        'review': _reviewController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).ratingSubmitted)),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).errorOccurred)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: CustomAppBar(title: lang.rateService),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.order.categoryName ?? 'Order #${widget.order.id}',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (widget.order.workerName != null)
              Text(
                '${lang.serviceProvider}: ${widget.order.workerName}',
                style: textTheme.bodySmall,
              ),
            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: _submitting ? null : () => setState(() => _stars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _stars ? Icons.star : Icons.star_border,
                        size: 44,
                        color: Colors.amber,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reviewController,
              enabled: !_submitting,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: lang.reviewHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_stars == 0 || _submitting) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(lang.submitRating),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
