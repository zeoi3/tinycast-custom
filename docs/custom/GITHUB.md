# GitHub 同步与账号授权

用户已选择：公开 Fork，仓库为 [zeoi3/tinycast-custom](https://github.com/zeoi3/tinycast-custom)，使用本机 GitHub CLI。

2026-10-12：已登录 zeoi3（系统钥匙串），Fork 和 origin 已创建；本次定制提交尚待确认推送。
本仓库提交身份使用 GitHub noreply 邮箱，仅写入本地 Git 配置，不更改全局作者设置。

## 与 ChatGPT 的关系

GitHub CLI 的登录授权对象是 GitHub CLI，不要求安装或授权 ChatGPT GitHub 连接器。
SSH 也是独立的 Git 认证方式；它需要在 GitHub 上添加本机公钥，创建 Fork 可在浏览器完成。
不连接 GitHub 插件不等于当前 AI 对话完全本地运行；在 Codex 中读取的项目内容仍可能进入任务上下文。

GitHub 官方说明：公开仓库的 Fork 是公开的，不能单独切换为私有。
如以后需要私有独立仓库，另行讨论迁移，不在此流程中更改选择。

## 登录

用户在自己的终端执行，或由当前任务启动后在浏览器完成授权：

```sh
gh auth login --hostname github.com --git-protocol https --web
gh auth status
```

GitHub CLI 优先使用系统凭据存储；若不可用可能退回明文文件，需要看 `gh auth status` 的存储位置。
不要输出 `gh auth token`，不要把 token、密码或 SSH 私钥粘贴到聊天或提交到仓库。

## 创建与同步

1. 登录后读取当前 GitHub login，确认是用户要用的账号。
2. 检查是否已有本项目的 Fork；优先复用，不重复创建同名仓库。
3. 创建 Fork 时不自动 clone，也不覆盖现有 remote：

```sh
gh repo fork abue-ammar/tinycast --fork-name tinycast-custom --clone=false
```

4. 核实仓库所有者、公开性及 parent，再把其真实 clone URL 配为 `origin`；不要用占位用户名执行命令。
5. 检查待推送 commit、分支、作者信息与 diff，取得本批 push 的用户确认。
6. 执行 `git push -u origin custom/zh-cn-lite`。不 force push，也不推送所有 tags/branches。
7. 对比 GitHub 分支 SHA 与本地 HEAD，确认一致后才能写“已同步”。可将 Fork 默认分支设为定制维护分支，以显示定制 README。

首次同步前若服务端拒绝浅历史，应按维护手册补全相关历史后重试；不要绕过验证或重写基线。
Fork 默认分支设置不会修改原仓库的 main。

## 官方资料

- [GitHub CLI 登录](https://cli.github.com/manual/gh_auth_login)
- [GitHub CLI Fork](https://cli.github.com/manual/gh_repo_fork)
- [Fork 可见性](https://docs.github.com/en/pull-requests/reference/forks)
- [Codex Cloud 的 GitHub 连接流程](https://learn.chatgpt.com/docs/cloud)
