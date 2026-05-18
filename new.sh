#!/bin/sh
set -e

# ────────────────────────────────────────────
# 常量配置（按需修改）
# ────────────────────────────────────────────
REPO_URL="git@github.com:chatclaw1203/chatclaw_backend.git"
PROJECT_DIR="$HOME/project/chatclaw_backend"
DEPLOY_KEY="$HOME/.ssh/deploy_key"

# ────────────────────────────────────────────
# 工具函数
# ────────────────────────────────────────────
log()  { echo "  $1"; }
ok()   { echo "✅ $1"; }
fail() { echo "❌ $1" >&2; exit 1; }

# ────────────────────────────────────────────
# 1. 安装 git
# ────────────────────────────────────────────
install_git() {
    if command -v git >/dev/null 2>&1; then
        ok "git 已安装，跳过：$(git --version)"
        return
    fi
    log "安装 git..."
    yum install -y git || fail "git 安装失败"
    ok "git 安装完成"
}

# ────────────────────────────────────────────
# 2. 配置 SSH
# ────────────────────────────────────────────
setup_ssh() {
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    # 自动生成 deploy key（如果不存在）
    if [ ! -f "$DEPLOY_KEY" ]; then
        log "未检测到 deploy key，自动生成..."
        ssh-keygen -t ed25519 -f "$DEPLOY_KEY" -C "chatclaw deploy" -N ""
        ok "deploy key 已生成"
    else
        ok "deploy key 已存在，跳过生成"
    fi
    chmod 600 "$DEPLOY_KEY"

    # 写入 SSH config（幂等：已有则跳过）
    if ! grep -q "github.com" ~/.ssh/config 2>/dev/null; then
        cat >> ~/.ssh/config << EOF

Host github.com
  HostName github.com
  IdentityFile $DEPLOY_KEY
  StrictHostKeyChecking no
EOF
        chmod 600 ~/.ssh/config
        log "SSH config 已写入"
    else
        log "SSH config 已存在，跳过"
    fi

    # 先验证，失败才提示添加公钥
    if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo ""
        echo "════════════════════════════════════════════"
        echo "  🔑 需要将公钥添加到 GitHub 仓库"
        echo "════════════════════════════════════════════"
        echo ""
        echo "  请按以下步骤操作："
        echo "  1. 打开 GitHub 仓库页面"
        echo "  2. 进入 Settings > Deploy keys > Add deploy key"
        echo "  3. 将下方公钥内容复制粘贴到 Key 输入框"
        echo "  4. 点击 Add key 保存"
        echo ""
        echo "  公钥内容："
        echo "────────────────────────────────────────────"
        cat "${DEPLOY_KEY}.pub"
        echo "────────────────────────────────────────────"
        echo ""
        echo "  完成后按 Enter 继续..."
        read -r _
        # 再验证一次
        ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" \
            || fail "GitHub SSH 认证失败，请确认公钥已正确添加到 Deploy keys"
    fi

    ok "GitHub SSH 认证成功"
}

# ────────────────────────────────────────────
# 3. 安装 Docker
# ────────────────────────────────────────────
install_docker() {
    if command -v docker >/dev/null 2>&1; then
        ok "Docker 已安装，跳过：$(docker --version)"
    else
        log "安装 Docker..."
        curl -fsSL https://get.docker.com | sh || fail "Docker 安装失败"
        ok "Docker 安装完成：$(docker --version)"
    fi

    # 确保服务运行
    systemctl enable docker --quiet
    systemctl is-active docker --quiet || systemctl start docker || fail "Docker 服务启动失败"

    # 检查 docker compose（v2 插件）
    docker compose version >/dev/null 2>&1 || fail "docker compose 插件未找到，请检查 Docker 版本是否 >= 20.10"
    ok "docker compose：$(docker compose version)"
}

# ────────────────────────────────────────────
# 4. 克隆或更新仓库
# ────────────────────────────────────────────
setup_repo() {
    if [ -d "$PROJECT_DIR/.git" ]; then
        log "仓库已存在，执行更新..."
        cd "$PROJECT_DIR"
        git fetch origin
        git checkout -- .
        git pull origin "$(git symbolic-ref --short HEAD)" || fail "git pull 失败"
        ok "仓库更新完成"
    else
        log "克隆仓库：$REPO_URL"
        mkdir -p "$(dirname "$PROJECT_DIR")"
        git clone "$REPO_URL" "$PROJECT_DIR" || fail "git clone 失败，请检查 deploy key 是否已添加"
        ok "仓库克隆完成"
    fi
}

# ────────────────────────────────────────────
# 5. 构建并部署
# ────────────────────────────────────────────
deploy() {
    cd "$PROJECT_DIR"

    # 检查 .env 是否存在
    [ -f ".env" ] || fail ".env 文件不存在，请先上传到 $PROJECT_DIR/.env"

    log "构建镜像..."
    docker compose build || fail "docker compose build 失败"

    log "启动服务..."
    docker compose up -d --remove-orphans || fail "docker compose up 失败"

    ok "部署完成，当前运行容器："
    docker compose ps
}

# ────────────────────────────────────────────
# 主流程
# ────────────────────────────────────────────
main() {
    echo "========================================"
    echo "  开始部署 chatclaw_backend"
    echo "========================================"

    install_git
    setup_ssh
    install_docker
    setup_repo
    deploy

    echo "========================================"
    echo "  🚀 全部完成！"
    echo "========================================"
}

main
