import SwiftUI

struct WebAISettingsView: View {
    @Environment(AppCore.self) private var core
    @State private var website = WebAI.defaultSite.absoluteString

    var body: some View {
        Form {
            Section("网页 AI") {
                Text("在面板搜索“网页 AI”，输入问题后回车。问题会复制到剪贴板，并打开网站，请自行粘贴发送。")
                Picker("选择网站", selection: $website) {
                    ForEach(WebAI.presets, id: \.0) { item in
                        Text(item.0).tag(item.1)
                    }
                    if !WebAI.presets.contains(where: { $0.1 == website }) {
                        Text("自定义").tag(website)
                    }
                }
                TextField("网站地址", text: $website)
                if WebAI.website(website) == nil {
                    Text("请输入以 https:// 或 http:// 开头的完整网址。")
                        .foregroundStyle(.secondary)
                }
                Button("保存网站") { save() }
                    .disabled(WebAI.website(website) == nil)
                Text("使用默认浏览器；网站登录状态由浏览器保管。本应用不保存 AI 密钥或聊天记录。")
                    .foregroundStyle(.secondary)
            }
            Section("快捷键与别名") {
                Button("在快速链接中设置") { core.settingsCoordinator.showSettings(tab: .quicklinks) }
                Text("网页 AI 与快速链接共用快捷键、别名和备份。你也可以添加其他 AI 网站链接。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            if let link = core.quicklinks.quicklink(id: WebAI.quicklinkID),
                let site = WebAI.site(in: link.link)
            {
                website = site.absoluteString
            }
        }
    }

    private func save() {
        guard let site = WebAI.website(website) else { return }
        var link =
            core.quicklinks.quicklink(id: WebAI.quicklinkID)
            ?? Quicklink(id: WebAI.quicklinkID, name: "网页 AI", link: "", iconSymbol: "sparkles")
        link.link = WebAI.template(site: site)
        do {
            if core.quicklinks.quicklink(id: link.id) == nil {
                _ = try core.quicklinks.add(link)
            } else {
                try core.quicklinks.update(link)
            }
            core.showMessage("网页 AI 网站已保存")
        } catch {
            core.showMessage("保存失败：\(error.localizedDescription)", tone: .danger)
        }
    }
}
