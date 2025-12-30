import 'package:flutter/material.dart';
import '../models/database/database_initializer.dart';
import '../models/repositories/focus_record_repository.dart';
import '../models/models.dart' show FocusRecordModel;

class StatisticsProvider extends ChangeNotifier {
  List<FocusRecordModel> _records = [];
  bool _isLoading = true;
  late final FocusRecordRepository _repository;

  List<FocusRecordModel> get records => _records;
  bool get isLoading => _isLoading;

  StatisticsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final db = DatabaseInitializer().database;
    _repository = FocusRecordRepository(db);
    await _loadRecords();
  }

  Future<void> _loadRecords() async {
    _isLoading = true;
    notifyListeners();

    _records = await _repository.getAllRecords();
    _records.sort((a, b) => b.startTime.compareTo(a.startTime));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecord(FocusRecordModel record) async {
    _records.insert(0, record);
    notifyListeners();
    await _repository.createRecord(record);
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
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    return _records
        .where((record) => record.startTime.isAfter(weekStart))
        .fold(0, (sum, record) => sum + (record.durationSeconds ~/ 60));
  }

  List<FocusRecordModel> get recentRecords {
    return _records.take(20).toList();
  }
}
