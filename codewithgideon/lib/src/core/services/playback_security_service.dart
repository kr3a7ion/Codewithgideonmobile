import 'package:flutter/services.dart';

class PlaybackSecurityService {
  PlaybackSecurityService._();

  static const MethodChannel _channel = MethodChannel(
    'codewithgideon/playback_security',
  );

  static Future<void> enableSecurePlayback() async {
    try {
      await _channel.invokeMethod<void>('enableSecurePlayback');
    } on PlatformException {
      // Best-effort hardening. Unsupported platforms can safely ignore this.
    }
  }

  static Future<void> disableSecurePlayback() async {
    try {
      await _channel.invokeMethod<void>('disableSecurePlayback');
    } on PlatformException {
      // Best-effort hardening. Unsupported platforms can safely ignore this.
    }
  }
}
