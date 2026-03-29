import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../services/realtime_service.dart';

class RealtimeNotification {
  final int id;
  final String message;
  final DateTime timestamp;
  final List<String> changedFields;
  final String scope;
  final int? scopeId;

  const RealtimeNotification({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.changedFields,
    required this.scope,
    this.scopeId,
  });
}

class RealtimeProvider extends ChangeNotifier {
  RealtimeProvider(this._auth) {
    _service.onEvent = _handleEvent;
    _auth.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final AuthProvider _auth;
  final RealtimeService _service = RealtimeService();

  final List<RealtimeNotification> _notifications = [];
  bool _connectedForSession = false;
  int _sequence = 0;
  int _lastDeliveredId = 0;

  List<RealtimeNotification> get notifications => List.unmodifiable(_notifications);
  RealtimeNotification? get latestNotification => _notifications.isEmpty ? null : _notifications.first;
  int get latestNotificationId => latestNotification?.id ?? 0;

  Future<void> syncAuthState() async {
    final shouldConnect = _auth.isLoggedIn;
    if (shouldConnect == _connectedForSession) return;
    _connectedForSession = shouldConnect;

    if (shouldConnect) {
      await _service.connect();
    } else {
      await _service.disconnect();
      _notifications.clear();
      _lastDeliveredId = 0;
      notifyListeners();
    }
  }

  void markLatestAsDelivered() {
    final latest = latestNotification;
    if (latest == null) return;
    _lastDeliveredId = latest.id;
    notifyListeners();
  }

  bool get hasUndeliveredNotification {
    final latest = latestNotification;
    return latest != null && latest.id != _lastDeliveredId;
  }

  Future<void> _handleEvent(RealtimeEvent event) async {
    if (event.event != 'rule_updated') return;

    await _auth.refreshUser();
    _sequence += 1;
    _notifications.insert(
      0,
      RealtimeNotification(
        id: _sequence,
        message: event.message,
        timestamp: DateTime.now(),
        changedFields: event.changedFields,
        scope: event.scope,
        scopeId: event.scopeId,
      ),
    );
    if (_notifications.length > 20) {
      _notifications.removeRange(20, _notifications.length);
    }
    notifyListeners();
  }

  void _handleAuthChanged() {
    syncAuthState();
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChanged);
    _service.dispose();
    super.dispose();
  }
}
