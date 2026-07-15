import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FcmSharedIsolate {
  final _channel = MethodChannel('fcm_shared_isolate');
  final _msg = <Map<String, Object?>>[];
  void Function(Map<String, Object?>)? _onMessage;
  void Function(String)? _onNewToken;

  FcmSharedIsolate() {
    _channel.setMethodCallHandler(handle);
  }

  Future<void> handle(MethodCall call) async {
    if (call.method == 'message') {
      final data = Map<String, Object?>.from(call.arguments);
      final onMessage = _onMessage;
      if (onMessage != null) {
        onMessage(data);
      } else {
        _msg.add(data);
      }
    } else if (call.method == 'token') {
      final String newToken = call.arguments;
      _onNewToken?.call(newToken);
    }
  }

  /// Returns the **cached** FCM token if already available. If not, then
  /// internal initialization should be awaited by listening to
  /// `onNewToken` in `setListeners()`.
  Future<String?> getToken() async {
    return await _channel.invokeMethod<String>('getToken');
  }

  void setListeners({
    void Function(Map<String, Object?>)? onMessage,
    void Function(String)? onNewToken,
  }) {
    _onMessage = onMessage;
    _onNewToken = onNewToken;
    if (onMessage != null) {
      _msg.forEach(onMessage);
      _msg.clear();
    }
  }

  Future<bool> requestPermission({
    bool sound = true,
    bool alert = true,
    bool badge = true,
    bool provisional = false,
  }) async {
    if (kIsWeb || !Platform.isIOS) {
      return true;
    }

    final bool result = await _channel.invokeMethod('requestPermission', {
      'sound': sound,
      'alert': alert,
      'badge': badge,
      'provisional': provisional,
    });
    return result;
  }
}
