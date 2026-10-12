# Tinycast Custom 使用说明

基于 Tinycast v0.11.19 的中文精简版。首版仅面向 Apple 芯片 Mac，最低系统要求 macOS 26。

## 安装与启动

1. 打开 DMG，将 **Tinycast Custom.app** 拖入 Applications；ZIP 解压后也可手动复制。
2. 启动应用，在首次引导中设置唤起快捷键；避免与 Tinycast、Raycast、Spotlight 使用同一组合。
3. 后续可从菜单栏打开面板或设置。应用默认不在 Dock 常驻。

如果你正在试用 **Tinycast Custom Dev**：先在开发版导出需要的配置，再退出开发版，安装并打开正式版后导入。
两版的数据相互隔离；不要同时使用相同的唤起快捷键。

本地构建采用专用自签名身份，**未经过 Apple 公证**。从其他电脑下载时可能提示无法验证开发者；
确认来源后，在系统“隐私与安全性”中按 macOS 提示允许打开。不要关闭整个系统的 Gatekeeper。

## 日常使用

- 输入应用名称、中文/拼音或别名，回车启动；在“应用”设置中配置独立快捷键。
- 输入数学表达式，回车复制答案；搜索“计算记录”查看历史。
- 在“快速链接”中添加网址、搜索模板、文件路径或其他应用的深度链接。
  支持 `{argument}`、`{clipboard}`、`{date}` 等原有占位符；`{clipboard}` 只读取当时的剪贴板。
- 在“Apple 快捷指令”中管理别名与快捷键；实际指令仍在苹果“快捷指令”应用中编辑。
- 在“命令”中添加命名的 Shell 命令；命令以当前用户身份执行，使用自己理解的脚本。
- 搜索“网页 AI”，填写“问题”后回车；或直接输入问题，选择结果底部的网页 AI 快速操作。
  内容会复制到剪贴板并打开网站，**需要在网页中自行粘贴发送**。默认 ChatGPT，可在“网页 AI”设置中切换或填写网址。
- “备份与导入”支持 `.tinycast` 和 Raycast 配置。仅恢复保留的设置与数据，停用模块的内容会跳过。

剪贴板历史、内置 AI 会话、扩展运行时、窗口管理、笔记、日历等模块在本版不启用。
复制网页 AI 问题或计算结果会替换当前剪贴板，但不会建立剪贴板历史。

## 权限

普通应用启动和复制结果不要求辅助功能权限。
组合修饰键映射、部分全局快捷键以及快速链接读取选中文字可能需要辅助功能权限；按界面提示开启。
macOS 或目标应用可能对 Apple 快捷指令、自定义命令请求额外授权；按你实际执行的动作决定。

## 更新与并存

本版独立标识为 `io.github.zeoi3.tinycastcustom`，可与官方版并存，数据不自动互相迁移。
显示名后续可调整，内部标识保持不变。升级时退出旧版，用新 App 覆盖同名应用。
本版没有官方 Tinycast 自动更新；维护采用按需修复，不要求跟随上游重构。

## 数据与卸载

- 偏好：`~/Library/Preferences/io.github.zeoi3.tinycastcustom.plist`
- 数据：`~/Library/Application Support/io.github.zeoi3.tinycastcustom/`
- 缓存：`~/Library/Caches/io.github.zeoi3.tinycastcustom/`
- 启用“同步设置文件”后：`~/.config/io.github.zeoi3.tinycastcustom/settings.json`

先导出需要保留的配置，再关闭开机启动并退出应用，最后将 App 移到废纸篓。
卸载 App 不自动删除个人配置；需要彻底清理时，再手动删除上述路径，勿误删官方 Tinycast 的数据。

## 来源

[定制版源码与反馈](https://github.com/zeoi3/tinycast-custom) ·
[上游 Tinycast](https://github.com/abue-ammar/tinycast)

许可与第三方声明随安装包保留。实际构建版本、源码提交见随包的 BUILD-INFO.txt；验收情况见交付记录。
