import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider(this._repository);

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  StreamSubscription<List<NotificationModel>>? _subscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount =>
      _notifications.where((notification) => !notification.read).length;

  void initialize() {
    _subscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _subscription = _repository
        .getNotifications()
        .listen(
          (notifications) {
        _notifications = notifications;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> clear() async {
    await _subscription?.cancel();

    _notifications = [];
    _isLoading = false;

    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}