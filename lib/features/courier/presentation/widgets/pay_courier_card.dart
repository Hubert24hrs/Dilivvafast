import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/domain/entities/bank_account.dart';
import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _field = Color(0xFFF3F4F6);
const _lime = Color(0xFFC1F11D);
const _green = Color(0xFF15803D);

String naira(double amount) => '₦${amount.toStringAsFixed(0)}';

/// Whether the customer should be shown how to pay: the courier has the
/// package (or has delivered it) and the order is not over.
bool showPayCourier(CourierOrderModel order) =>
    order.driverId != null &&
    const [
      OrderStatus.pickedUp,
      OrderStatus.inTransit,
      OrderStatus.delivered,
    ].contains(order.status);

/// The customer pays their courier directly — inDrive-style, no wallet.
///
/// Cash: hand it over at the door. Bank transfer: the courier's account is
/// shown (copied onto the order by the server when their offer was accepted),
/// the customer transfers and taps "I've sent it", and the courier confirms
/// it arrived.
class PayCourierCard extends ConsumerStatefulWidget {
  const PayCourierCard({super.key, required this.order});
  final CourierOrderModel order;

  @override
  ConsumerState<PayCourierCard> createState() => _PayCourierCardState();
}

class _PayCourierCardState extends ConsumerState<PayCourierCard> {
  bool _busy = false;

  Future<void> _run(Future<Either<Failure, Unit>> Function() action) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: context.palette.danger,
        ),
      ),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final amount = naira(order.totalFare);
    final repo = ref.read(courierRepositoryProvider);

    if (order.paymentStatus == PaymentStatus.paid) {
      return _Panel(
        color: const Color(0xFFE8F5E9),
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: _green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paid $amount · ${order.paymentMethod.label.toLowerCase()}',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Your courier confirmed they received it.',
            style: TextStyle(color: _muted),
          ),
        ],
      );
    }

    final sent = order.paymentStatus == PaymentStatus.sent;
    final method = order.paymentMethod;

    return _Panel(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pay your courier',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          order.status == OrderStatus.delivered
              ? 'Pay now that your package has been delivered.'
              : 'Pay when your package is delivered.',
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 12),
        SegmentedButton<PaymentMethod>(
          segments: const [
            ButtonSegment(
              value: PaymentMethod.cash,
              icon: Icon(Icons.payments_outlined),
              label: Text('Cash'),
            ),
            ButtonSegment(
              value: PaymentMethod.transfer,
              icon: Icon(Icons.account_balance_outlined),
              label: Text('Bank transfer'),
            ),
          ],
          selected: {method},
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: _lime,
            selectedForegroundColor: _ink,
          ),
          onSelectionChanged: sent || _busy
              ? null
              : (s) => _run(() => repo.setPaymentMethod(order.id, s.first)),
        ),
        const SizedBox(height: 12),
        if (method == PaymentMethod.cash)
          Text(
            'Hand $amount in cash to your courier when they deliver.',
            style: const TextStyle(color: _ink, height: 1.4),
          )
        else ...[
          if (order.courierBank != null)
            BankDetails(account: order.courierBank!)
          else
            const Text(
              "Your courier hasn't added a bank account yet. Pay in cash, "
              'or ask them for their account details in the chat.',
              style: TextStyle(color: _ink, height: 1.4),
            ),
          const SizedBox(height: 12),
          if (sent)
            const Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: _muted, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transfer sent — waiting for your courier to confirm '
                    'they received it.',
                    style: TextStyle(color: _ink, height: 1.4),
                  ),
                ),
              ],
            )
          else if (order.courierBank != null)
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => repo.markPaymentSent(order.id)),
                style: FilledButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: _ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text("I've sent $amount"),
              ),
            ),
        ],
      ],
    );
  }
}

/// Bank, account number (tap to copy) and account name.
class BankDetails extends StatelessWidget {
  const BankDetails({super.key, required this.account});
  final BankAccount account;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row('Bank', account.bankName),
          _row(
            'Account number',
            account.accountNumber,
            trailing: IconButton(
              tooltip: 'Copy account number',
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: account.accountNumber),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account number copied')),
                  );
                }
              },
            ),
          ),
          _row('Account name', account.accountName),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: _muted)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        ?trailing,
        if (trailing == null) const SizedBox(width: 8),
      ],
    ),
  );
}

/// The courier's side: collect the fare and confirm it arrived.
class CollectPaymentCard extends ConsumerStatefulWidget {
  const CollectPaymentCard({super.key, required this.order});
  final CourierOrderModel order;

  @override
  ConsumerState<CollectPaymentCard> createState() => _CollectPaymentCardState();
}

class _CollectPaymentCardState extends ConsumerState<CollectPaymentCard> {
  bool _busy = false;

  Future<void> _confirm() async {
    final order = widget.order;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Received ${naira(order.totalFare)}?'),
        content: Text(
          order.paymentMethod == PaymentMethod.transfer
              ? 'Only confirm once the transfer shows in your bank account.'
              : 'Only confirm once you have the cash in hand.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, I received it'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(courierRepositoryProvider)
        .confirmPaymentReceived(order.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: context.palette.danger,
        ),
      ),
      (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment confirmed'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final amount = naira(order.totalFare);
    final transfer = order.paymentMethod == PaymentMethod.transfer;

    if (order.paymentStatus == PaymentStatus.paid) {
      return _Panel(
        color: const Color(0xFFE8F5E9),
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: _green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivered and paid · $amount',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final String message;
    if (order.paymentStatus == PaymentStatus.sent) {
      message =
          'The customer says they have sent $amount to your bank account. '
          'Check your bank app, then confirm.';
    } else if (transfer) {
      message = order.courierBank == null
          ? 'The customer wants to pay $amount by transfer, but you have no '
                'bank account saved. Add one, or collect cash.'
          : 'The customer will transfer $amount to your '
                '${order.courierBank!.bankName} account.';
    } else {
      message = 'Collect $amount in cash from the customer.';
    }

    return _Panel(
      children: [
        Text(
          'Delivered — collect $amount',
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(message, style: const TextStyle(color: _ink, height: 1.4)),
        if (transfer && order.courierBank == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/driver/bank-account'),
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Add bank account'),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _busy ? null : _confirm,
            style: FilledButton.styleFrom(
              backgroundColor: _lime,
              foregroundColor: _ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text("I've received $amount"),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children, this.color = _field});
  final List<Widget> children;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
