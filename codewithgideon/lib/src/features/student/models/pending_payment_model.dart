enum PendingPaymentKind { initial, topUp }

class PendingPaymentModel {
  const PendingPaymentModel({
    required this.kind,
    required this.weeks,
    required this.amount,
    required this.reference,
    required this.isPending,
  });

  final PendingPaymentKind kind;
  final int weeks;
  final int amount;
  final String reference;
  final bool isPending;
}
