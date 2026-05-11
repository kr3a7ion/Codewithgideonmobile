import '../../catalog/models/course_model.dart';
import '../../student/models/pending_payment_model.dart';
import '../../student/models/student_profile_model.dart';

enum PaymentFlowKind { initial, topUp }

extension PaymentFlowKindX on PaymentFlowKind {
  String get apiValue => this == PaymentFlowKind.topUp ? 'topup' : 'initial';

  String get title =>
      this == PaymentFlowKind.topUp ? 'Top Up Access' : 'Complete Registration';

  String get actionLabel => this == PaymentFlowKind.topUp
      ? 'Continue To Paystack'
      : 'Pay And Finish Registration';
}

class PaymentCheckoutModel {
  const PaymentCheckoutModel({
    required this.kind,
    required this.profile,
    required this.course,
  });

  final PaymentFlowKind kind;
  final StudentProfileModel profile;
  final CourseModel course;

  int get totalProgramWeeks => course.durationWeeks;
  int get committedWeeks => profile.weeksToCommit;
  int get remainingWeeks {
    final remaining = course.durationWeeks - profile.weeksToCommit;
    return remaining < 0 ? 0 : remaining;
  }

  int get maxAllowedWeeks =>
      kind == PaymentFlowKind.topUp ? remainingWeeks : totalProgramWeeks;

  int get suggestedWeeks {
    final pending = matchingPendingPayment;
    if (pending != null) {
      return pending.weeks;
    }
    if (kind == PaymentFlowKind.topUp) {
      return maxAllowedWeeks == 0 ? 0 : 1;
    }
    if (profile.weeksToCommit > 0) {
      return profile.weeksToCommit.clamp(1, totalProgramWeeks);
    }
    return totalProgramWeeks >= 4
        ? 4
        : totalProgramWeeks.clamp(1, totalProgramWeeks);
  }

  PendingPaymentModel? get matchingPendingPayment {
    final pending = profile.pendingPayment;
    if (pending == null || !pending.isPending) return null;
    final isTopUpPending = pending.kind == PendingPaymentKind.topUp;
    if (kind == PaymentFlowKind.topUp && isTopUpPending) return pending;
    if (kind == PaymentFlowKind.initial && !isTopUpPending) return pending;
    return null;
  }

  bool get hasMatchingPendingPayment => matchingPendingPayment != null;
}

class PaymentPriceBreakdown {
  const PaymentPriceBreakdown({
    required this.weeks,
    required this.weeklyRate,
    required this.basePrice,
    required this.totalFee,
    required this.yourFeeShare,
    required this.studentFeeShare,
    required this.totalPrice,
    required this.yourRevenue,
  });

  final int weeks;
  final int weeklyRate;
  final int basePrice;
  final int totalFee;
  final int yourFeeShare;
  final int studentFeeShare;
  final int totalPrice;
  final int yourRevenue;

  int get basePriceKobo => basePrice * 100;
  int get totalFeeKobo => totalFee * 100;
  int get yourFeeShareKobo => yourFeeShare * 100;
  int get studentFeeShareKobo => studentFeeShare * 100;
  int get totalPriceKobo => totalPrice * 100;
  int get yourRevenueKobo => yourRevenue * 100;
}

const double paystackRate = 0.015;
const int paystackFlat = 100;
const int paystackCap = 2000;
const int flatThreshold = 2500;

int getPaystackFee(int amount) {
  final flat = amount >= flatThreshold ? paystackFlat : 0;
  final fee = (amount * paystackRate).round() + flat;
  return fee > paystackCap ? paystackCap : fee;
}

class SplitFeeResult {
  const SplitFeeResult({
    required this.amountPerTxn,
    required this.totalFeePerTxn,
    required this.yourFeeSharePerTxn,
    required this.studentFeeSharePerTxn,
    required this.chargeStudentPerTxn,
    required this.youReceivePerTxn,
    required this.transactions,
    required this.totalCharged,
    required this.totalFees,
    required this.yourTotalCost,
    required this.studentTotalExtra,
    required this.yourTotalRevenue,
    required this.targetRevenue,
  });

  final int amountPerTxn;
  final int totalFeePerTxn;
  final int yourFeeSharePerTxn;
  final int studentFeeSharePerTxn;
  final int chargeStudentPerTxn;
  final int youReceivePerTxn;
  final int transactions;
  final int totalCharged;
  final int totalFees;
  final int yourTotalCost;
  final int studentTotalExtra;
  final int yourTotalRevenue;
  final int targetRevenue;
}

SplitFeeResult calculateSplitFee(int weeklyFee, int weeks, String mode) {
  assert(weeks >= 1 && weeks <= 12, 'weeks must be 1-12');

  final amountPerTxn = mode == 'upfront' ? weeklyFee * weeks : weeklyFee;
  final transactions = mode == 'upfront' ? 1 : weeks;

  final totalFee = getPaystackFee(amountPerTxn);
  final yourFeeShare = totalFee ~/ 2;
  final studentFeeShare = totalFee - yourFeeShare;
  final chargeStudent = amountPerTxn + studentFeeShare;
  final youReceivePerTxn = chargeStudent - totalFee;

  return SplitFeeResult(
    amountPerTxn: amountPerTxn,
    totalFeePerTxn: totalFee,
    yourFeeSharePerTxn: yourFeeShare,
    studentFeeSharePerTxn: studentFeeShare,
    chargeStudentPerTxn: chargeStudent,
    youReceivePerTxn: youReceivePerTxn,
    transactions: transactions,
    totalCharged: chargeStudent * transactions,
    totalFees: totalFee * transactions,
    yourTotalCost: yourFeeShare * transactions,
    studentTotalExtra: studentFeeShare * transactions,
    yourTotalRevenue: youReceivePerTxn * transactions,
    targetRevenue: weeklyFee * weeks,
  );
}

class PaymentInitializationResult {
  const PaymentInitializationResult({
    required this.authorizationUrl,
    required this.reference,
  });

  final String authorizationUrl;
  final String reference;
}

class PaymentVerificationResult {
  const PaymentVerificationResult({
    required this.safeWeeks,
    required this.maxWeeks,
    required this.alreadyProcessed,
  });

  final int safeWeeks;
  final int maxWeeks;
  final bool alreadyProcessed;
}
