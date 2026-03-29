import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/api.dart' show storage;
import '../core/config.dart';

class RealtimeEvent {
  final String event;
  final String message;
  final List<String> changedFields;
  final String scope;
  final int? scopeId;

  const RealtimeEvent({
    required this.event,
    required this.message,
    required this.changedFields,
    required this.scope,
    this.scopeId,
  });

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeEvent(
      event: json['event']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      changedFields: (json['changed_fields'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      scope: json['scope']?.toString() ?? 'user',
      scopeId: (json['scope_id'] as num?)?.toInt(),
    );
  }
}

class RealtimeService {
  WebSocket? _socket;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _connecting = false;
  bool _manualDisconnect = false;

  Future<void> Function(RealtimeEvent event)? onEvent;

  Future<void> connect() async {
    if (_disposed || _connecting || _socket != null) return;

    final token = await storage.read(key: 'token');
    if (token == null || token.isEmpty) return;

    _connecting = true;
    _manualDisconnect = false;

    try {
      final socket = await WebSocket.connect(AppConfig.notificationsUri(token).toString());
      _socket = socket;
      _subscription = socket.listen(
        _handleMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _socket?.close();
    _socket = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final event = RealtimeEvent.fromJson(json);
      final callback = onEvent;
      if (callback != null) {
        callback(event);
      }
    } catch (_) {}
  }

  void _scheduleReconnect() {
    _subscription = null;
    _socket = null;
    if (_disposed || _manualDisconnect || _reconnectTimer != null) return;

    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _reconnectTimer = null;
      connect();
    });
  }
}
