// Preferences.cj - 本地存储工具
package utils

import ohos.data.preferences.*
import ohos.app.context.*

public class Preferences {
    private let prefs: ohos.data.preferences.Preferences
    private static var instances: HashMap<String, Preferences> = HashMap<String, Preferences>()

    private init(prefs: ohos.data.preferences.Preferences) {
        this.prefs = prefs
    }

    public static func get(name: String): Preferences {
        if (instances.containsKey(name)) {
            return instances.get(name)
        }

        let context = Context.getApplicationContext()
        let prefsHelper = PreferencesHelper()
        let prefs = prefsHelper.getPreferences(context, name)
        let instance = Preferences(prefs)
        instances.put(name, instance)
        return instance
    }

    public func putString(key: String, value: String): Unit {
        prefs.putString(key, value)
    }

    public func getString(key: String, defaultValue: String = ""): String {
        return prefs.getString(key, defaultValue)
    }

    public func putInt(key: String, value: Int32): Unit {
        prefs.putInt(key, value)
    }

    public func getInt(key: String, defaultValue: Int32 = 0): Int32 {
        return prefs.getInt(key, defaultValue)
    }

    public func putInt64(key: String, value: Int64): Unit {
        prefs.putLong(key, value)
    }

    public func getInt64(key: String, defaultValue: Int64 = 0): Int64 {
        return prefs.getLong(key, defaultValue)
    }

    public func putBool(key: String, value: Bool): Unit {
        prefs.putBoolean(key, value)
    }

    public func getBool(key: String, defaultValue: Bool = false): Bool {
        return prefs.getBoolean(key, defaultValue)
    }

    public func putFloat(key: String, value: Float32): Unit {
        prefs.putFloat(key, value)
    }

    public func getFloat(key: String, defaultValue: Float32 = 0.0f): Float32 {
        return prefs.getFloat(key, defaultValue)
    }

    public func remove(key: String): Unit {
        prefs.delete(key)
    }

    public func clear(): Unit {
        prefs.clear()
    }

    public func flush(): Unit {
        prefs.flush()
    }
}
