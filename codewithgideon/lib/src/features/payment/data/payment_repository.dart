import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/payment_config.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../student/data/student_repository.dart';
import '../../student/models/student_profile_model.dart';
import '../models/payment_checkout_model.dart';

class PaymentRepository {
  PaymentRepository({
    required FirebaseFirestore firebaseFirestore,
    required StudentRepository studentRepository,
    required CatalogRepository catalogRepository,
  }) : _firebaseFirestore = firebaseFirestore,
       _studentRepository = studentRepository,
       _catalogRepository = catalogRepository;

  final FirebaseFirestore _firebaseFirestore;
  final StudentRepository _studentRepository;
  final CatalogRepository _catalogRepository;

  Future<PaymentCheckoutModel> loadCheckout({
    required String uid,
    required PaymentFlowKind kind,
  }) async {
    StudentProfileModel? profile;
    for (var attempt = 0; attempt < 4; attempt++) {
      profile = await _studentRepository.getStudentProfileByUid(uid);
      if (profile != null) break;
      await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }
    if (profile == null) {
      throw StateError(
        'Student profile could not be found for payment. Please try again in a moment.',
      );
    }
    final course = await _catalogRepository.getCourseForPath(
      profile.pathId,
      courseId: profile.courseId,
    );
    return PaymentCheckoutModel(kind: kind, profile: profile, course: course);
  }

  Future<void> setPendingPayment({
    required String uid,
    required PaymentFlowKind kind,
    required int weeks,
    required int amount,
    required String reference,
  }) {
    return _firebaseFirestore.collection('users').doc(uid).set({
      'pendingPayment': {
        'kind': kind.apiValue,
        'status': 'Pending',
        'weeks': weeks,
        'amount': amount,
        'reference': reference,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  /// Headers for the payment functions. The login token lets the server
  /// confirm the payment belongs to the signed-in student.
  Future<Map<String, String>> _headers() async {
    String? token;
    try {
      token = await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      token = null;
    }
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<PaymentInitializationResult> initializePayment({
    required String email,
    required int amountKobo,
    required String reference,
    required Map<String, Object?> metadata,
  }) async {
    final response = await http.post(
      Uri.parse(PaymentConfig.initializeUrl),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'amount': amountKobo,
        'reference': reference,
        'currency': 'NGN',
        'callbackUrl': PaymentConfig.callbackUrl,
        'metadata': metadata,
      }),
    );

    final json = _decodeJson(
      response,
      fallback:
          'The payment checkout service is not returning valid payment data right now.',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        describeHttpError(json, 'Could not initialize payment.'),
      );
    }

    final data = json['data'];
    if (data is! Map) {
      throw StateError(
        'Payment gateway returned an invalid initialization response.',
      );
    }

    final authorizationUrl = '${data['authorization_url'] ?? ''}'.trim();
    final resolvedReference = '${data['reference'] ?? reference}'.trim();
    if (authorizationUrl.isEmpty) {
      throw StateError('Payment checkout URL was missing from the response.');
    }

    return PaymentInitializationResult(
      authorizationUrl: authorizationUrl,
      reference: resolvedReference.isEmpty ? reference : resolvedReference,
    );
  }

  Future<PaymentVerificationResult> verifyPayment({
    required PaymentCheckoutModel checkout,
    required PaymentPriceBreakdown pricing,
    required String reference,
  }) async {
    final response = await http.post(
      Uri.parse(PaymentConfig.verifyUrl),
      headers: await _headers(),
      body: jsonEncode({
        'reference': reference,
        'uid': checkout.profile.uid,
        'expectedAmount': pricing.totalPriceKobo,
        'weeks': pricing.weeks,
        'kind': checkout.kind.apiValue,
        'cohortId': checkout.profile.cohortId,
        'cohortLabel': checkout.profile.cohortLabel,
        'cohortKey': checkout.profile.cohortKey,
        'path': checkout.profile.pathTitle,
        'pathId': checkout.profile.pathId,
        'courseId': checkout.profile.courseId,
        'courseMaxWeeks': checkout.course.durationWeeks,
        'weeklyRate': checkout.course.pricePerWeek,
      }),
    );

    final json = _decodeJson(
      response,
      fallback: 'We could not confirm your payment yet.',
    );
    if (json['needsReview'] == true) {
      return PaymentVerificationResult(
        safeWeeks: 0,
        maxWeeks: checkout.course.durationWeeks,
        alreadyProcessed: false,
        needsReview: true,
        message: (json['error'] as String?)?.trim().isNotEmpty == true
            ? json['error'] as String
            : "Your payment was received and is being reviewed. Your classes will unlock once it's confirmed.",
      );
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        json['ok'] != true) {
      throw StateError(
        describeHttpError(json, 'We could not confirm your payment yet.'),
      );
    }

    return PaymentVerificationResult(
      safeWeeks: (json['safeWeeks'] as num?)?.toInt() ?? pricing.weeks,
      maxWeeks:
          (json['maxWeeks'] as num?)?.toInt() ?? checkout.course.durationWeeks,
      alreadyProcessed: json['alreadyProcessed'] == true,
    );
  }

  PaymentPriceBreakdown quote({
    required PaymentCheckoutModel checkout,
    required int weeks,
  }) {
    final safeWeeks = checkout.maxAllowedWeeks <= 0
        ? 0
        : weeks.clamp(1, checkout.maxAllowedWeeks);
    // The server charges the base course price (weeks x weekly rate).
    // Any Paystack fee is added by Paystack at checkout, not by the app.
    final basePrice = checkout.course.pricePerWeek * safeWeeks;
    return PaymentPriceBreakdown(
      weeks: safeWeeks,
      weeklyRate: checkout.course.pricePerWeek,
      basePrice: basePrice,
      totalFee: 0,
      yourFeeShare: 0,
      studentFeeShare: 0,
      totalPrice: basePrice,
      yourRevenue: basePrice,
    );
  }

  String generateReference() {
    final random = Random.secure().nextInt(1000).toString().padLeft(3, '0');
    return 'CWG_${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}_$random';
  }

  Map<String, dynamic> _decodeJson(
    http.Response response, {
    required String fallback,
  }) {
    final raw = response.body.trim();
    if (raw.isEmpty) return <String, dynamic>{};

    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final looksLikeHtml =
        raw.startsWith('<') ||
        raw.toLowerCase().contains('<html') ||
        contentType.contains('text/html');
    if (looksLikeHtml) {
      throw StateError(
        '$fallback Please try again. If it continues, contact support so we can check the Paystack endpoint.',
      );
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      throw StateError(fallback);
    }

    throw StateError(fallback);
  }

  static String describeHttpError(Map<String, dynamic> json, String fallback) {
    final direct = '${json['error'] ?? ''}'.trim();
    if (direct.isNotEmpty) return direct;

    final details = json['details'];
    if (details is Map<String, dynamic>) {
      final detailMessage = '${details['message'] ?? details['error'] ?? ''}'
          .trim();
      if (detailMessage.isNotEmpty) return detailMessage;
    }

    return fallback;
  }
}
