// ExportService.cj - 导出服务
package services

import models.*
import std.io.*
import ohos.app.context.*

public class ExportService {
    private let httpClient: HttpClient
    private let context: Context

    public init(httpClient: HttpClient, context: Context) {
        this.httpClient = httpClient
        this.context = context
    }

    // 导出PDF
    public func exportToPDF(resumeId: Int64): Result<String> {
        let endpoint = "${ApiConfig.EXPORT_PDF}?resume_id=${resumeId}"
        let response = httpClient.get(endpoint)

        if (response.isSuccess()) {
            // 保存PDF文件
            let fileName = "resume_${resumeId}_${getTimeStamp()}.pdf"
            let filePath = saveFile(fileName, response.body, "application/pdf")
            return Result<String>.success(filePath)
        }

        return Result<String>.failure(response.error)
    }

    // 导出Word
    public func exportToDocx(resumeId: Int64): Result<String> {
        let endpoint = "${ApiConfig.EXPORT_DOCX}?resume_id=${resumeId}"
        let response = httpClient.get(endpoint)

        if (response.isSuccess()) {
            // 保存DOCX文件
            let fileName = "resume_${resumeId}_${getTimeStamp()}.docx"
            let filePath = saveFile(fileName, response.body, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
            return Result<String>.success(filePath)
        }

        return Result<String>.failure(response.error)
    }

    // 导出HTML
    public func exportToHTML(resume: Resume, template: Template): Result<String> {
        let html = generateHTML(resume, template)
        let fileName = "resume_${resume.id}_${getTimeStamp()}.html"
        let filePath = saveFile(fileName, html, "text/html")
        return Result<String>.success(filePath)
    }

    // 保存文件
    private func saveFile(fileName: String, content: String, mimeType: String): String {
        try {
            // 获取文件保存路径
            let filesDir = context.getFilesDir()
            let exportDir = "${filesDir}/exports"

            // 创建导出目录
            let dir = File(exportDir)
            if (!dir.exists()) {
                dir.mkdirs()
            }

            // 写入文件
            let filePath = "${exportDir}/${fileName}"
            let file = File(filePath)
            let writer = FileWriter(file)
            writer.write(content)
            writer.close()

            println("File saved: ${filePath}")
            return filePath

        } catch (e: Exception) {
            println("Failed to save file: ${e.message}")
            return ""
        }
    }

    // 生成HTML内容
    private func generateHTML(resume: Resume, template: Template): String {
        let sb = StringBuilder()
        sb.append("<!DOCTYPE html>\n")
        sb.append("<html lang=\"zh-CN\">\n")
        sb.append("<head>\n")
        sb.append("  <meta charset=\"UTF-8\">\n")
        sb.append("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n")
        sb.append("  <title>${resume.title}</title>\n")
        sb.append("  <style>\n")
        sb.append(generateCSS(template))
        sb.append("  </style>\n")
        sb.append("</head>\n")
        sb.append("<body>\n")
        sb.append("  <div class=\"resume-container\">\n")
        sb.append(resume.content)
        sb.append("  </div>\n")
        sb.append("</body>\n")
        sb.append("</html>")
        return sb.toString()
    }

    // 生成CSS样式
    private func generateCSS(template: Template): String {
        let style = template.style
        let sb = StringBuilder()
        sb.append("    * { margin: 0; padding: 0; box-sizing: border-box; }\n")
        sb.append("    body {\n")
        sb.append("      font-family: '${style.fontFamily}', sans-serif;\n")
        sb.append("      font-size: ${style.fontSize}px;\n")
        sb.append("      line-height: ${style.lineHeight};\n")
        sb.append("      color: ${style.textColor};\n")
        sb.append("      background-color: ${style.backgroundColor};\n")
        sb.append("    }\n")
        sb.append("    .resume-container {\n")
        sb.append("      max-width: 800px;\n")
        sb.append("      margin: 0 auto;\n")
        sb.append("      padding: ${style.padding}px;\n")
        sb.append("    }\n")
        sb.append("    h1, h2, h3 { color: ${style.primaryColor}; }\n")
        sb.append("    .section { margin-bottom: 20px; }\n")
        sb.append("    .section-title {\n")
        sb.append("      border-bottom: 2px solid ${style.primaryColor};\n")
        sb.append("      padding-bottom: 5px;\n")
        sb.append("      margin-bottom: 10px;\n")
        sb.append("    }\n")
        return sb.toString()
    }

    // 获取时间戳
    private func getTimeStamp(): Int64 {
        return System.currentTimeMillis()
    }
}
