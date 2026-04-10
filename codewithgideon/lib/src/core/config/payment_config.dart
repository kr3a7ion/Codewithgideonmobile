class PaymentConfig {
  static const initializeUrl = String.fromEnvironment(
    'PAYSTACK_INITIALIZE_URL',
    defaultValue:
        'https://us-central1-codewithgideon.cloudfunctions.net/initializePaystackPayment',
  );

  static const verifyUrl = String.fromEnvironment(
    'PAYSTACK_VERIFY_URL',
    defaultValue:
        'https://us-central1-codewithgideon.cloudfunctions.net/verifyPaystackPayment',
  );

  static const callbackUrl = String.fromEnvironment(
    'PAYSTACK_CALLBACK_URL',
    defaultValue: 'https://codewithgideon.com/',
  );
}
