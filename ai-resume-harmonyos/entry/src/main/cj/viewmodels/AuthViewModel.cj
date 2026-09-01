// AuthViewModel.cj - 认证视图模型
package viewmodels

import models.*
import services.*
import ohos.arkui.state.*

/**
 * 认证视图模型
 *
 * 管理用户认证状态，提供登录、注册、登出等功能
 * 使用 Observable 模式通知 UI 更新
 */
@Observed
public class AuthViewModel extends Observable {
    private var currentUser: ?User = None
    private var isAuthenticated: Bool = false
    private var isLoading: Bool = false
    private var errorMessage: String = ""

    private let authService: AuthService

    public init() {
        this.authService = AuthService()
        // 检查是否已登录
        this.isAuthenticated = authService.isAuthenticated()
    }

    // 登录
    public func login(email: String, password: String): Bool {
        isLoading = true
        errorMessage = ""
        notifyUIUpdate()

        let result = authService.login(email, password)
        isLoading = false

        if (result.isSuccess()) {
            isAuthenticated = true
            notifyUIUpdate()
            return true
        } else {
            errorMessage = result.getError()
            notifyUIUpdate()
            return false
        }
    }

    // 注册
    public func register(email: String, username: String, password: String, fullName: String): Bool {
        isLoading = true
        errorMessage = ""
        notifyUIUpdate()

        let result = authService.register(email, username, password, fullName)
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<User>) {
                currentUser = Some(value.get())
            }
            notifyUIUpdate()
            return true
        } else {
            errorMessage = result.getError()
            notifyUIUpdate()
            return false
        }
    }

    // 登出
    public func logout(): Unit {
        authService.logout()
        currentUser = None
        isAuthenticated = false
        notifyUIUpdate()
    }

    // 刷新Token
    public func refreshToken(): Bool {
        let result = authService.refreshToken()
        return result.isSuccess()
    }

    // Getter方法
    public func getUser(): ?User {
        return currentUser
    }

    public func isLoggedIn(): Bool {
        return isAuthenticated
    }

    public func isLoading(): Bool {
        return isLoading
    }

    public func getError(): String {
        return errorMessage
    }

    // 通知 UI 更新
    private func notifyUIUpdate(): Unit {
        // Observable 模式会自动通知观察者
        update()
    }
}
