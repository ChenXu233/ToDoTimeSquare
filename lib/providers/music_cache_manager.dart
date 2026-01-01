import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sample/music_track.dart';

/// 音乐缓存管理器 - 负责所有缓存相关的操作
class MusicCacheManager {
  int _cacheMaxBytes = 200 * 1024 * 1024; // 默认 200 MB
  final Map<String, String> _cachedTrackMap = {}; // trackId -> localPath
  static const int _kCacheMinBytes = 1024; // 最小有效缓存大小

  // 持久化键
  static const _kCacheMaxBytesKey = 'pomodoro_cacheMaxBytes';
  static const _kCachedTrackMapKey = 'pomodoro_cachedTrackMap';

  // Getters
  int get cacheMaxBytes => _cacheMaxBytes;
  Map<String, String> get cachedTrackMap => _cachedTrackMap;

  MusicCacheManager();

  // --- 缓存文件路径管理 ---

  Future<Directory> getCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/music_cache');
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
    return cacheDir;
  }

  String getCachedFileName(MusicTrack track) {
    final encoded = base64Url.encode(utf8.encode(track.sourceUrl));
    return 'cache_$encoded.mp3';
  }

  Future<File> getCachedFile(MusicTrack track) async {
    final cacheDir = await getCacheDir();
    final filename = getCachedFileName(track);
    return File('${cacheDir.path}/$filename');
  }

  // --- 缓存验证 ---

  Future<bool> isValidCacheFile(File file) async {
    try {
      if (!await file.exists()) return false;
      final length = await file.length();
      if (length < _kCacheMinBytes) return false;

      final bytes = await file.openRead(0, 4).first;
      final header = bytes.first;
      if (header == 0xFF || (bytes.length >= 2 && bytes[0] == 0x49 && bytes[1] == 0x44)) {
        return true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isTrackCached(MusicTrack track) async {
    if (kIsWeb) return false;
    try {
      final file = await getCachedFile(track);
      return await isValidCacheFile(file);
    } catch (_) {
      return false;
    }
  }

  // --- 缓存持久化 ---

  Future<void> persistCacheMap([SharedPreferences? prefs]) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await p.setString(_kCachedTrackMapKey, json.encode(_cachedTrackMap));
      await p.setInt(_kCacheMaxBytesKey, _cacheMaxBytes);
    } catch (e) {
      debugPrint('Error persisting cached track map: $e');
    }
  }

  Future<void> loadCacheSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final maxBytes = prefs.getInt(_kCacheMaxBytesKey);
      if (maxBytes != null && maxBytes > 0) _cacheMaxBytes = maxBytes;

      final mapJson = prefs.getString(_kCachedTrackMapKey);
      if (mapJson != null && mapJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(mapJson);
        decoded.forEach((key, value) {
          if (value is String) _cachedTrackMap[key] = value;
        });
      }
    } catch (e) {
      debugPrint('Error loading cache settings: $e');
    }
  }

  // --- 缓存大小管理 ---

  Future<int> calculateCacheSize() async {
    if (kIsWeb) return 0;
    try {
      final dir = await getCacheDir();
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<void> enforceCacheSize() async {
    try {
      final maxBytes = _cacheMaxBytes;
      int total = await calculateCacheSize();
      if (total <= maxBytes) return;

      final dir = await getCacheDir();
      final files = <File>[];
      await for (final entity in dir.list(recursive: false)) {
        if (entity is File) files.add(entity);
      }

      files.sort((a, b) {
        final am = a.lastModifiedSync();
        final bm = b.lastModifiedSync();
        return am.compareTo(bm);
      });

      for (final f in files) {
        if (total <= maxBytes) break;
        try {
          final len = await f.length();
          await f.delete();
          total -= len;
          final entryKey = _cachedTrackMap.entries.firstWhere(
            (e) => e.value == f.path,
            orElse: () => const MapEntry('', ''),
          );
          if (entryKey.key.isNotEmpty) {
            _cachedTrackMap.remove(entryKey.key);
          }
        } catch (e) {
          debugPrint("Error deleting cached file ${f.path}: $e");
        }
      }

      await persistCacheMap();
    } catch (e) {
      debugPrint('Error enforcing cache size: $e');
    }
  }

  Future<void> setCacheMaxBytes(int bytes) async {
    _cacheMaxBytes = bytes;
    await persistCacheMap();
    await enforceCacheSize();
  }

  // --- 缓存下载 ---

  Future<bool> downloadTrack(MusicTrack track) async {
    if (track.isLocal || _cachedTrackMap.containsKey(track.id)) return true;
    if (kIsWeb) {
      debugPrint('downloadTrack: skipping cache/download on web for ${track.id}');
      return false;
    }

    try {
      final file = await getCachedFile(track);

      if (await isValidCacheFile(file)) {
        _cachedTrackMap[track.id] = file.path;
        await persistCacheMap();
        return true;
      }

      final response = await http.get(Uri.parse(track.sourceUrl)).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode == 200) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);

        if (response.bodyBytes.length < _kCacheMinBytes) {
          debugPrint('Downloaded file too small, possible corruption');
          return false;
        }

        _cachedTrackMap[track.id] = file.path;
        await persistCacheMap();
        await enforceCacheSize();
        return true;
      } else {
        debugPrint('Download failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint("Download error: $e");
      return false;
    }
  }

  Future<void> deleteTrackCache(String trackId) async {
    if (kIsWeb) return;
    final path = _cachedTrackMap[trackId];
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint("Error deleting cache file for $trackId: $e");
      }
      _cachedTrackMap.remove(trackId);
      await persistCacheMap();
    }
  }

  // --- 缓存清理 ---

  Future<void> clearCache() async {
    if (kIsWeb) {
      _cachedTrackMap.clear();
      await persistCacheMap();
      return;
    }

    try {
      final dir = await getCacheDir();
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          try {
            if (entity is File) await entity.delete();
            if (entity is Directory) await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
      _cachedTrackMap.clear();
      await persistCacheMap();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
