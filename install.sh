#!/bin/sh
set -e

do_install() {


    # 装 git
    echo "安装 git..."
    yum install -y git

    
    echo "开始安装 Docker..."

    curl -fsSL https://get.docker.com | sh

    echo "启动 Docker 服务..."
    systemctl enable --now docker

    echo "✅ Docker 安装完成！"
    docker --version
    docker compose version
}

do_install
