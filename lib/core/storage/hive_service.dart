import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/core/error/exceptions.dart';

/// Service for opening and accessing Hive boxes used for local caching.
///
/// Boxes store serialized JSON maps so no Hive adapters are needed —
/// models serialize themselves via json_serializable.
class HiveService {
  static Box<dynamic>? _projectsBox;
  static Box<dynamic>? _tasksBox;
  static Box<dynamic>? _notificationsBox;

  /// Must be called after [Hive.initFlutter()] in [main].
  static Future<void> openBoxes() async {
    _projectsBox = await Hive.openBox(AppConstants.hiveBoxProjects);
    _tasksBox = await Hive.openBox(AppConstants.hiveBoxTasks);
    _notificationsBox = await Hive.openBox(AppConstants.hiveBoxNotifications);
  }

  // ─── Accessors ────────────────────────────────────────────────────────────

  static Box<dynamic> get projectsBox {
    if (_projectsBox == null || !_projectsBox!.isOpen) {
      throw const CacheException(message: 'Projects box is not open.');
    }
    return _projectsBox!;
  }

  static Box<dynamic> get tasksBox {
    if (_tasksBox == null || !_tasksBox!.isOpen) {
      throw const CacheException(message: 'Tasks box is not open.');
    }
    return _tasksBox!;
  }

  static Box<dynamic> get notificationsBox {
    if (_notificationsBox == null || !_notificationsBox!.isOpen) {
      throw const CacheException(message: 'Notifications box is not open.');
    }
    return _notificationsBox!;
  }

  // ─── Generic Cache Helpers ────────────────────────────────────────────────

  /// Saves a list of JSON maps to a box under [key].
  static Future<void> cacheList(Box box, String key, List<Map<String, dynamic>> items) async {
    await box.put(key, items);
  }

  /// Reads a cached list of JSON maps from a box under [key].
  static List<Map<String, dynamic>>? readList(Box box, String key) {
    final raw = box.get(key);
    if (raw == null) return null;
    return (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> closeBoxes() async {
    await Hive.close();
  }
}
