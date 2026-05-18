#!/bin/sh
set -e

do_install() {
    # 装 git
    echo "安装 git..."
    yum install -y git

    # 配置 SSH
    mkdir -p ~/.ssh
    cat > ~/.ssh/config << EOF
Host github.com
  IdentityFile ~/.ssh/deploy_key
EOF

    # 安装 Docker
    echo "开始安装 Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
    echo "✅ Docker 安装完成！"
    docker --version
    docker compose version

    # clone 仓库
    echo "开始 clone 仓库..."
    cd ~
    mkdir project
    cd project
    git clone git@github.com:chatclaw1203/chatclaw_backend.git
    echo "仓库下载完成" 

    echo "🚀 开始部署..."
    cd /root/project/chatclaw_backend
    git checkout -- .
    git pull
    docker compose build
    docker compose up -d
    echo "✅ 部署完成"
}

do_install
