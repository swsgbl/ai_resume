// ResumeViewModel.cj - 简历视图模型
package viewmodels

import models.*
import services.*
import std.collection.*
import ohos.arkui.state.*

/**
 * 简历视图模型
 *
 * 管理简历数据和状态，提供简历的增删改查功能
 * 使用 Observable 模式通知 UI 更新
 */
@Observed
public class ResumeViewModel extends Observable {
    private var resumes: ArrayList<Resume> = ArrayList<Resume>()
    private var currentResume: ?Resume = None
    private var isLoading: Bool = false
    private var errorMessage: String = ""

    private let resumeService: ResumeService
    private let aiService: AIService

    public init(httpClient: HttpClient) {
        this.resumeService = ResumeService(httpClient)
        this.aiService = AIService(httpClient)
    }

    // 获取简历列表
    public func loadResumes(): Unit {
        isLoading = true
        errorMessage = ""
        notifyUIUpdate()

        let result = resumeService.getResumes()
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<ArrayList<Resume>>) {
                resumes = value.get()
            }
        } else {
            errorMessage = result.getError()
        }

        notifyUIUpdate()
    }

    // 获取单个简历
    public func loadResume(id: Int64): Unit {
        isLoading = true
        errorMessage = ""
        notifyUIUpdate()

        let result = resumeService.getResume(id)
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<Resume>) {
                currentResume = Some(value.get())
            }
        } else {
            errorMessage = result.getError()
        }

        notifyUIUpdate()
    }

    // 创建简历
    public func createResume(title: String, templateId: Int64): ?Resume {
        isLoading = true
        errorMessage = ""
        notifyUIUpdate()

        let result = resumeService.createResume(title, templateId)
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<Resume>) {
                let newResume = value.get()
                resumes.add(newResume)
                notifyUIUpdate()
                return Some(newResume)
            }
        } else {
            errorMessage = result.getError()
            notifyUIUpdate()
        }

        return None
    }

    // 更新简历
    public func updateResume(resume: Resume): Bool {
        isLoading = true
        errorMessage = ""
        notifyUIUpdate()

        let result = resumeService.updateResume(resume.id, resume)
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<Resume>) {
                currentResume = Some(value.get())
                // 更新列表中的简历
                for (i in 0..resumes.size()) {
                    if (resumes.get(i).id == resume.id) {
                        resumes.set(i, value.get())
                        break
                    }
                }
                notifyUIUpdate()
                return true
            }
        } else {
            errorMessage = result.getError()
            notifyUIUpdate()
        }

        return false
    }

    // 删除简历
    public func deleteResume(id: Int64): Bool {
        isLoading = true
        errorMessage = ""
        notifyUIUpdate()

        let result = resumeService.deleteResume(id)
        isLoading = false

        if (result.isSuccess()) {
            // 从列表中移除
            for (i in 0..resumes.size()) {
                if (resumes.get(i).id == id) {
                    resumes.removeAt(i)
                    break
                }
            }
            notifyUIUpdate()
            return true
        } else {
            errorMessage = result.getError()
            notifyUIUpdate()
        }

        return false
    }

    // AI生成内容
    public func generateWithAI(request: AIGenerateRequest): ?String {
        isLoading = true
        errorMessage = ""
        notifyUIUpdate()

        let result = aiService.generateContent(request)
        isLoading = false

        if (result.isSuccess()) {
            let value = result.getValue()
            if (value is Some<AIGenerateResponse>) {
                notifyUIUpdate()
                return Some(value.get().content)
            }
        } else {
            errorMessage = result.getError()
            notifyUIUpdate()
        }

        return None
    }

    // Getter方法
    public func getResumes(): ArrayList<Resume> {
        return resumes
    }

    public func getCurrentResume(): ?Resume {
        return currentResume
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
