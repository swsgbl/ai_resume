import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 存储服务
///
/// 封装本地存储操作，提供统一接口
class StorageService {
  StorageService._internal();

  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  SharedPreferences? _prefs;
  FlutterSecureStorage? _secureStorage;
  bool _initialized = false;

  /// 初始化存储服务
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    _initialized = true;
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // ============ String 操作 ============

  /// 存储字符串
  Future<void> setString(String key, String value) async {
    await _ensureInitialized();
    await _prefs!.setString(key, value);
  }

  /// 获取字符串
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs!.getString(key);
  }

  // ============ Bool 操作 ============

  /// 存储布尔值
  Future<void> setBool(String key, bool value) async {
    await _ensureInitialized();
    await _prefs!.setBool(key, value);
  }

  /// 获取布尔值
  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs!.getBool(key);
  }

  // ============ Int 操作 ============

  /// 存储整数
  Future<void> setInt(String key, int value) async {
    await _ensureInitialized();
    await _prefs!.setInt(key, value);
  }

  /// 获取整数
  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _prefs!.getInt(key);
  }

  // ============ Double 操作 ============

  /// 存储双精度浮点数
  Future<void> setDouble(String key, double value) async {
    await _ensureInitialized();
    await _prefs!.setDouble(key, value);
  }

  /// 获取双精度浮点数
  Future<double?> getDouble(String key) async {
    await _ensureInitialized();
    return _prefs!.getDouble(key);
  }

  // ============ StringList 操作 ============

  /// 存储字符串列表
  Future<void> setStringList(String key, List<String> value) async {
    await _ensureInitialized();
    await _prefs!.setStringList(key, value);
  }

  /// 获取字符串列表
  Future<List<String>?> getStringList(String key) async {
    await _ensureInitialized();
    return _prefs!.getStringList(key);
  }

  // ============ 安全存储操作 ============

  /// 存储敏感数据（加密）
  Future<void> setSecureString(String key, String value) async {
    await _ensureInitialized();
    await _secureStorage!.write(key: key, value: value);
  }

  /// 获取敏感数据
  Future<String?> getSecureString(String key) async {
    await _ensureInitialized();
    return await _secureStorage!.read(key: key);
  }

  /// 删除敏感数据
  Future<void> removeSecureString(String key) async {
    await _ensureInitialized();
    await _secureStorage!.delete(key: key);
  }

  // ============ 删除操作 ============

  /// 删除指定key
  Future<void> remove(String key) async {
    await _ensureInitialized();
    await _prefs!.remove(key);
  }

  /// 清除所有数据
  Future<void> clear() async {
    await _ensureInitialized();
    await _prefs!.clear();
    // 清除安全存储中的所有key
    await _secureStorage!.deleteAll();
  }

  /// 检查key是否存在
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    return _prefs!.containsKey(key);
  }

  /// 获取所有keys
  Future<Set<String>> getKeys() async {
    await _ensureInitialized();
    return _prefs!.getKeys();
  }
}
