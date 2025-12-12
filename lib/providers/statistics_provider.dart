import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/focus_record.dart';

class StatisticsProvider extends ChangeNotifier {
  List<FocusRecord> _records = [];
  bool _isLoading = true;

  List<FocusRecord> get records => _records;
  bool get isLoading => _isLoading;

  StatisticsProvider() {
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final List<String>? recordsJson = prefs.getStringList('focus_records');

    if (recordsJson != null) {
      _records =
          recordsJson.map((jsonStr) => FocusRecord.fromJson(jsonStr)).toList();
      // Sort by start time descending
      _records.sort((a, b) => b.startTime.compareTo(a.startTime));
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecord(FocusRecord record) async {
    _records.insert(0, record);
    notifyListeners();
    await _saveRecords();
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> recordsJson =
        _records.map((record) => record.toJson()).toList();
    await prefs.setStringList('focus_records', recordsJson);
  }

  // Statistics Getters

  int get totalFocusMinutes {
    return _records.fold(
      0,
      (sum, record) => sum + (record.durationSeconds ~/ 60),
    );
  }

  int get todayFocusMinutes {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _records
        .where((record) => record.startTime.isAfter(todayStart))
        .fold(0, (sum, record) => sum + (record.durationSeconds ~/ 60));
  }

  int get thisWeekFocusMinutes {
    final now = DateTime.now();
    // Find the start of the week (Monday)
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    
    return _records
        .where((record) => record.startTime.isAfter(weekStart))
        .fold(0, (sum, record) => sum + (record.durationSeconds ~/ 60));
  }
  
  // Helper to get recent records
  List<FocusRecord> get recentRecords {
    return _records.take(20).toList();
  }
}
