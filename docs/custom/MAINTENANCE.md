# 定制版维护手册

## 基线与 Git 约定

- 基线固定于 v0.11.19 / `126c998d87cd7e93bd5e3437098d9c646eb6a714`。
- `upstream`：原项目，只取源码和修复；主分支是 `main`。
- `origin`：用户公开 Fork；定制维护分支是 `custom/zh-cn-lite`。
- 中文 commit，按目的拆分。pull/merge 之前提交当前工作；push 前展示并取得用户对具体目标与内容的确认。
- 不直接使用 GitHub 的“Sync fork”更新定制分支，也不运行 `git pull upstream main` 做日常维护。

新克隆后运行：

```sh
./Scripts/setup-custom.sh
```

脚本只修改当前仓库的 Git 配置：建立/核实 upstream、禁止向 upstream 推送、默认向 origin 推送、设置 pull 为 fast-forward only。
这些 `.git/config` 设置不会随 commit 上传，所以每个新克隆都要执行。脚本不登录、不拉取、不推送、不修改全局配置。

## 当前克隆方式

初始化为 shallow + `blob:none` partial clone；稀疏工作目录包含 `.github`、`Tinycast`、`Tinycast.xcodeproj`、`Scripts`、`Tests`、`docs` 及根文件。
`website/` 仍在 Git 历史中，只是未检出；这不是已删除网站代码。后续读取旧文件可能触发 Git 下载。

```sh
git rev-parse --is-shallow-repository
git sparse-checkout list
git remote -v
```

若追溯旧修复或推送时缺少祖先历史，先确保当前工作已提交，再按需扩展历史：

```sh
git fetch --unshallow --filter=blob:none --no-tags upstream main
```

仅在 shallow 输出为 true 时使用 `--unshallow`。普通 fetch 不会把上游 main 合并到当前代码。
需要查看未检出的目录时用 `git sparse-checkout add <目录>`；不要为查看一个文件下载全部网站资源。

## 引入一项修复

1. 确认 Bug 在本版保留功能中存在，并尽量复现；只影响关闭模块的修复一般不引入。
2. 提交当前工作；在 `fix/<简短名称>` 分支操作。
3. 获取目标提交，阅读 diff、依赖和上游测试；不要默认它可独立应用。
4. 改动独立时 `git cherry-pick -x <SHA>`，记录来源；如需中文化 commit 总结，保留 cherry-pick 来源说明。
5. 依赖大重构时，提取修复思路在旧结构上实现；若代价过高，说明方案与代价再决定，不能顺带导入全部重构。
6. 跑相关回归、Debug 构建及 lint；记录未覆盖的验证。
7. 更新 [修复台账](UPSTREAM-FIXES.md)，审查 diff 后合回定制维护分支。
8. 向用户展示待推送提交、远程与分支，确认后 push。

每项补丁尽量单独提交；需要回退已发布补丁时优先 `git revert <本地提交>`，不改写远程历史。
上游修复用不上、依赖不合理或无法验证时，允许继续维护基线；但系统兼容和安全修复应按实际影响评估。

## 构建与验证

完整步骤见 [development.md](../development.md)、[testing.md](../testing.md)。
先核对 `xcodebuild -version`、`xcodegen --version`、`swiftlint version`。
本项目是 XcodeGen + Xcode 工程，不是 SwiftPM；生成工程使用 `xcodegen generate`。

```sh
./Scripts/run-tests.sh <相关测试名>
./Scripts/lint.sh
xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

无签名构建仅用于编译验证。要安装并验证辅助功能权限，按签名文档配置定制版身份。
纯文档/仓库配置变更只验证对应文档、配置和脚本；交付安装包前运行全套测试和核心人工流程。

## Fork 发布边界

- 上游 `release.yml` 会使用官方应用标识和发行流程；本 Fork 尚未配置自己的发行。
- 上游 Release、Triage、Co-authors 的 jobs 已加原仓库限制；Website 原本已有同类限制。本 Fork 不执行这些原作者流程。
- 为定制版发布前，单独设计自己的发布工作流；不得移除限制就直接运行官方发布。
- 原有 CONTRIBUTING、Issue 模板和 docs/release.md 描述上游流程；本 Fork 按根 AGENTS 和 custom 文档执行。
- 保留 LICENSE、NOTICE 和来源。日后公开分发构建时同时检查对应源码与许可证要求。

## 工作结束时

更新 PROJECT 的实现状态，以及本次新增的修复记录。
报告 commit、验证范围、待办与 GitHub 是否已成功同步；不要把“已本地 commit”写成“已推送”。
