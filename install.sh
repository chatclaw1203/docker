
#!/bin/sh
set -e

do_install() {
    echo "✅ Docker 安装完成！"
    docker --version
}

do_install
