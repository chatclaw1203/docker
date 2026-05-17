#!/bin/sh
set -e

do_install() {

    # 装 git
    echo "安装 git..."
    yum install -y git

    mkdir -p ~/.ssh
    cat > ~/.ssh/config << EOF
    Host github.com
      IdentityFile ~/.ssh/deploy_key
    EOF

    
    echo "开始安装 Docker..."

    curl -fsSL https://get.docker.com | sh

    echo "启动 Docker 服务..."
    systemctl enable --now docker

    echo "✅ Docker 安装完成！"
    docker --version
    docker compose version


    echo "开始安装 clone 仓库..."
    cd ~
    mkdir project 
    cd project
    git clone git@github.com:chatclaw1203/chatclaw_backend.git
    echo "仓库下载完成"
    echo "开始纸执行docker yml 文件"
    
}

do_install
