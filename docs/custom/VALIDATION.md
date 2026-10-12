# 首版 0.1.0 验证记录

更新：2026-10-12。此文件记录实际证据，未通过的步骤不能当作交付完成。

| 检查 | 当前结果 |
| --- | --- |
| 产品范围及网页 AI 请求解析 | 独立 Swift 测试通过，覆盖禁止的热键、协议限制及中文/特殊字符 |
| 快速链接协调器 | 通过；请求参数、选中文字回退、编辑与删除等原有测试 |
| 设置搜索静态目标 | 通过；按本版有效页面检查，保留稳定定位键 |
| Swift 6 语法解析 | 通过；不等于类型检查或构建 |
| 完整应用构建 | 最终 Debug、Release 构建均成功 |
| 全套测试 | 94/94 全部通过，1025 秒；之后的菜单原文保护修改单独复测快速链接协调器 |
| SwiftLint | 完整 Xcode 下 lint-clean；新代码产生的空 setter 警告已修正 |
| 简体中文界面与输入法 | 主面板与网页 AI 设置已检查；用户正在试用，输入法和外部交互待确认 |
| 基线与定制版内存/CPU | 已测新配置、不开面板的后台场景；单次观察，不声明普遍节省比例 |
| DMG/ZIP 安装与签名 | 已生成；DMG 挂载、拷贝后签名、后台运行及 ZIP 完整性检查通过 |

## 预检说明

初次全套预检在实现前启动，但执行期间源码变动，部分测试同时遇到 CLT 缺少 SwiftUI 宏。
因此整次运行标记为无效预检，日志 `build/validation/preflight-incomplete.log` 不作为基线或最终验收。
后续只在源码稳定时运行全套测试；期间不修改它使用的源文件或测试脚本。

## 构建与安装包

- 上游基线：`126c998d87cd7e93bd5e3437098d9c646eb6a714`（v0.11.19）。
- 安装包源码：`364ece24a1a517e2cc49724c907cc7879f909c77`；之后的交付记录提交不改变应用代码。
- 工具链：Xcode 27.0（27A266a）、Swift 6.4、macOS SDK 27.0。
- 主机：macOS 27.0（26A428）、Apple 芯片 arm64、16 GiB 内存。最低部署目标 macOS 26；没有在 macOS 26 或 Intel Mac 上实测。
- Release 使用 `SWIFT_COMPILATION_MODE=incremental`，保留 Release 优化；限制编译并发，避免全模块优化造成大量换页。
- 定制与基线构建均成功，仅出现 AppIntents 元数据提取跳过提示；没有依赖 AppIntents，不影响本版功能。
- 本机专用自签名 `Tinycast Custom Local`；`codesign --verify --deep --strict` 通过，未进行 Apple 公证。
- DMG 已只读挂载，确认 Applications 入口、使用说明、BUILD-INFO、许可证，复制 App 后再次验证签名。
- ZIP CRC 完整性、Bundle ID、0.1.0 版本、独立 URL scheme、中文资源、LICENSE/NOTICE 均通过；不包含剪贴板/听写辅助进程、扩展 JS 运行时和表情关键词资源。

| 产物 | 大小 | SHA256 |
| --- | --- | --- |
| `build/TinycastCustom-0.1.0-arm64.dmg` | 8,934,889 字节 | `02a468be4e2998c029b369dda0e7e440b50dc2c6117d788da9e6c394e91ce06c` |
| `build/TinycastCustom-0.1.0-arm64.zip` | 8,174,018 字节 | `b1218d750585aaf2718595a37941247a0b9995edea3e7cd81ed956da4d0a1985` |

证据保存在本机忽略目录 `build/validation/`：`release-full-build.log`、`release-build.log`、`debug-build.log`、`package-build.log`、`package-verification.log`。安装包来源同时写在 `build/BUILD-INFO.txt`；校验值见 `build/SHA256SUMS.txt`。

## 人工检查边界

- 开发版已签名启动，检查主面板中文内容与网页 AI 设置（ChatGPT 默认值、网址配置与手动粘贴提示）。
- 用户正在自行试用。按用户要求，不继续切换界面或重启开发版；自动检查不等于这些人工流程已经验收。
- 待用户确认：中文输入法组合输入、应用实际启动、全局/按应用热键、计算器复制、链接参数/当前剪贴板/日期、Apple 快捷指令、Shell 命令、整套配置导入导出、网页 AI 打开与粘贴。
- `Scripts/check-backup-wire.sh` 已通过：真实应用模块的 Apple 快捷指令热键 Codable 往返和旧备份缺字段兼容，日志 `backup-wire-final.log`。这只证明编码恢复，不代替系统热键触发检查。
- 不发布公开 Release；本轮 GitHub 源码同步仍需用户确认，核对远程 HEAD 后才能标记完成。

## 资源观察

开发版在用户试用时的物理占用为 117.1 MiB、峰值 127.1 MiB；该读数来自 Debug、有交互且未控制负载，不能用于计算节省比例。开发版数据目录仅发现快速链接数据库、排序记录和引导标记，没有创建剪贴板历史或 AI 会话数据库。

Release 对比：两版均用优化的 arm64 构建、隔离的新配置、空快速链接数据和相同功能开关；关闭非保留功能，开启命令/快速链接/Apple 快捷指令。跳过引导，不打开面板，先测定制版再测基线，每版运行约一分钟。基线只改独立 Bundle ID、名称与空 URL scheme，避免覆盖官方配置。定制版从最终 DMG 拷贝到 `build/InstallCheck/` 后运行。

| 计划采样时点 | 定制版物理占用 | 基线物理占用 | 两版采样 CPU |
| --- | --- | --- | --- |
| 启动后 5 秒 | 25.2 MiB | 30.6 MiB | 0.0% |
| 启动后 30 秒 | 24.5 MiB | 30.0 MiB | 0.0% |
| 启动后 60 秒 | 24.5 MiB | 28.4 MiB | 0.0% |

`vmmap` 自身耗时，实际采样完成时点分别约 8/33/62 秒与 8/35/62 秒。记录的是物理占用；RSS 会受到压缩和共享页影响，不用来计算收益。最后一次观察差约 3.9 MiB；用户其他应用仍在运行，只有一次顺序测试，不应推广为稳定节省比例。

定制版仅创建快速链接数据库和引导标记；同样关闭剪贴板历史的基线仍创建 `clipboard.sqlite3` 及 `support-reminder.json`。这支持本次延迟初始化确实避免了不需要的数据库创建，但不等于已经验证所有长期后台行为。脚本结束后已清理自己的两套临时配置，未修改开发版试用数据。

原始结果：`runtime-comparison.json`、`runtime-comparison.log`、`custom-files.json`、`baseline-files.json`、各时点 `*-memory-*s.txt`。本机辅助脚本：`build/validation/measure-runtime.py`；只有对应 Bundle ID 尚无用户配置时才能运行，禁止覆盖既有数据。

面板反复开关、外部操作和长期使用增长测试未做，待用户试用或后续专项检查；本次不承诺内存下降比例。

## 本轮发现与处理

- 最终全套日志：`build/validation/final-tests.log`；追加检查：`quicklink-final.log`。原始全套预检及首轮失败日志仅留作排查，不作为最终通过证据。

- 首次打开主面板崩溃：移除扩展环境后，仍有 `ExtensionSelectionForwarder` 监听器挂在根界面。已移除，重新构建后主面板正常。
- `form-input-test` 以浅色像素定位文字，但继承了主机浅色外观；测试窗口固定深色后通过。未修改产品的输入框或主机外观。
- `launcher-settings-file-test` 的 AppEntry 替身补充 `alternateTitles`，与真实类型的英文检索词保持一致。
- 无源文件参数的新增测试导致 xargs 将下一行续接；给 `custom-profile-test` 显式传入 `-parse-as-library`。
- 首轮 `ext-test` 的固定时间等待在并行构建高负载下失败；最终复测已通过。该扩展功能在产品中关闭。
- 原始 Release 全模块优化与并行测试同时执行造成明显换页。已停止该次基线构建，基线与定制 Release 均改用增量编译及受限并发，仍保留 Release 优化级别。
