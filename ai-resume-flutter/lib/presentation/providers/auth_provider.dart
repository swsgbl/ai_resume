import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';

/// 认证状态
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }

  AuthState copyWithUser(User? user) {
    return AuthState(
      user: user,
      isLoading: isLoading,
      isAuthenticated: user != null,
      error: error,
    );
  }
}

/// 认证Provider
///
/// 管理用户认证状态
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// 初始化，检查登录状态
  Future<void> initialize() async {
    state = const AuthState(isLoading: true);

    try {
      await _repository.initialize();
      final isLoggedIn = await _repository.isLoggedIn();

      if (isLoggedIn) {
        final user = await _repository.getCurrentUser();
        state = AuthState(
          user: user,
          isAuthenticated: user != null,
        );
      } else {
        state = const AuthState();
      }
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  /// 用户登录
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);

    try {
      final user = await _repository.login(
        email: email,
        password: password,
      );
      state = state.copyWithUser(user);
    } catch (e) {
      state = AuthState(error: e.toString());
      rethrow;
    }
  }

  /// 用户注册
  Future<void> register({
    required String email,
    required String password,
    required String nickname,
    String? code,
  }) async {
    state = const AuthState(isLoading: true);

    try {
      final user = await _repository.register(
        email: email,
        password: password,
        nickname: nickname,
        code: code,
      );
      state = state.copyWithUser(user);
    } catch (e) {
      state = AuthState(error: e.toString());
      rethrow;
    }
  }

  /// 发送验证码
  Future<void> sendVerificationCode(String email) async {
    try {
      await _repository.sendVerificationCode(email);
    } catch (e) {
      state = AuthState(error: e.toString());
      rethrow;
    }
  }

  /// 登出
  Future<void> logout() async {
    state = const AuthState(isLoading: true);

    try {
      await _repository.logout();
      state = const AuthState();
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  /// 清除错误
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// 修改密码
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = const AuthState(isLoading: true);

    try {
      await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// 请求注销账号
  ///
  /// 根据GDPR和个人信息保护法，用户有权要求删除其个人数据
  /// 此操作将：
  /// 1. 发送确认邮件到用户邮箱
  /// 2. 设置30天删除倒计时
  /// 3. 记录注销请求原因
  ///
  /// 返回删除倒计时天数，失败返回null
  Future<int?> requestAccountDeletion({
    String? reason,
    bool exportData = false,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);

    try {
      final response = await _repository.requestAccountDeletion(
        reason: reason,
        exportData: exportData,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return response.deletionDays ?? 30;
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// 取消注销请求
  ///
  /// 在30天宽限期内可以取消注销
  Future<bool> cancelAccountDeletion() async {
    state = const AuthState(isLoading: true);

    try {
      await _repository.cancelAccountDeletion();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// 请求导出个人数据
  ///
  /// 用户可以在注销前请求导出所有个人数据
  /// 后端会生成数据包并发送到用户邮箱
  ///
  /// 返回导出响应信息
  Future<DataExportResponse> exportAccountData() async {
    state = const AuthState(isLoading: true);

    try {
      final response = await _repository.exportAccountData();
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// 永久删除账号
  ///
  /// 注意：这是立即删除，没有30天宽限期
  /// 仅用于用户主动确认后的最终操作
  Future<void> deleteAccount() async {
    state = const AuthState(isLoading: true);

    try {
      await _repository.logout();
      state = const AuthState();
    } catch (e) {
      state = AuthState(error: e.toString());
      rethrow;
    }
  }
}

/// 认证状态Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repository);

  // 自动初始化
  Future.microtask(() => notifier.initialize());

  return notifier;
});

/// 是否已登录Provider
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});

/// 当前用户Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});
