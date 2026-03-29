import 'package:flutter/material.dart';
import '../models/checkin.dart';
import '../services/checkin_service.dart';

class CheckinProvider extends ChangeNotifier {
  List<CheckIn> records = [];
  bool loading = false;
  String? error;

  bool checkinLoading = false;
  String? checkinResult;
  bool checkinSuccess = false;

  DateTime? filterDateFrom;
  DateTime? filterDateTo;

  Future<void> loadHistory({String? dateFrom, String? dateTo}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final list = await checkinService.getCheckins(dateFrom: dateFrom, dateTo: dateTo);
      records = list.map((j) => CheckIn.fromJson(j)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> doCheckin(double? lat, double? lng, {String type = 'sign_in'}) async {
    checkinLoading = true;
    checkinResult = null;
    notifyListeners();
    try {
      final raw = await checkinService.createCheckin(lat: lat, lng: lng, type: type);
      final record = CheckIn.fromJson(raw);
      records.insert(0, record);
      checkinSuccess = record.isSuccess;
      checkinResult = record.isSuccess ? '打卡成功' : '打卡异常：${record.statusLabel}';
    } catch (e) {
      checkinSuccess = false;
      checkinResult = e.toString();
    } finally {
      checkinLoading = false;
      notifyListeners();
    }
  }

  void setDateFilter(DateTime? from, DateTime? to) {
    filterDateFrom = from;
    filterDateTo = to;
    final df = from != null ? _fmt(from) : null;
    final dt = to != null ? _fmt(to) : null;
    loadHistory(dateFrom: df, dateTo: dt);
  }

  void clearFilter() {
    filterDateFrom = null;
    filterDateTo = null;
    loadHistory();
  }

  void clearCheckinResult() {
    checkinResult = null;
    notifyListeners();
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
