#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(git -C "$script_dir" rev-parse --show-toplevel)
cd "$repo_dir"

upstream_url=https://github.com/abue-ammar/tinycast.git
if git remote get-url upstream >/dev/null 2>&1; then
    actual_url=$(git remote get-url upstream)
    if [ "$actual_url" != "$upstream_url" ]; then
        echo "upstream 地址与预期不同，未修改配置：$actual_url" >&2
        exit 1
    fi
else
    git remote add upstream "$upstream_url"
fi

if git remote get-url origin >/dev/null 2>&1; then
    origin_url=$(git remote get-url origin)
    case "$origin_url" in
        *abue-ammar/tinycast|*abue-ammar/tinycast.git)
            echo "origin 仍指向原仓库，请先改为自己的 Fork。" >&2
            exit 1
            ;;
    esac
fi

git config --local remote.upstream.pushurl DISABLED
git config --local remote.pushDefault origin
git config --local push.default current
git config --local pull.ff only

echo "已配置本仓库：upstream 禁止推送；默认推送 origin；pull 仅允许快进。"
echo "任何 push 仍须先取得用户对目标分支与提交的确认。"
