#!/bin/bash

# 定义颜色
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 脚本下载目录
SCRIPT_DIR="/etc/sing-box/scripts"

# 检测是否处于科学环境的函数
function check_network() {
    echo -e "${CYAN}检测是否处于科学环境...${NC}"
    STATUS_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "https://www.google.com")

    if [ "$STATUS_CODE" -eq 200 ]; then
        echo -e "${CYAN}当前处于代理环境${NC}"
        return 0
    else
        echo -e "${RED}当前不在科学环境下，请配置正确的网络后重试!${NC}"
        return 1
    fi
}

# 初次检测网络环境
if ! check_network; then
    read -p "是否执行网络更改脚本？(y/n): " network_choice
    if [[ "$network_choice" =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/set_network.sh"
        # 再次检测网络环境
        if ! check_network; then
            echo -e "${RED}网络配置更改后依然不在科学环境下，请检查网络配置!${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

# 检查 sing-box 是否已安装
if command -v sing-box &> /dev/null; then
    echo -e "${CYAN}sing-box 已安装，跳过安装步骤${NC}"
else
    # 添加官方 GPG 密钥和仓库
    sudo mkdir -p /etc/apt/keyrings
    sudo curl -fsSL https://sing-box.app/gpg.key -o /etc/apt/keyrings/sagernet.asc
    sudo chmod a+r /etc/apt/keyrings/sagernet.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/sagernet.asc] https://deb.sagernet.org/ * *" | sudo tee /etc/apt/sources.list.d/sagernet.list > /dev/null

    # 始终更新包列表
    echo "正在更新包列表，请稍候..."
    sudo apt-get update -qq > /dev/null 2>&1

    # 提示用户是否升级系统
    read -p "是否升级系统？(y/n): " upgrade_choice
    if [[ "$upgrade_choice" =~ ^[Yy]$ ]]; then
        echo "正在升级系统，请稍候..."
        sudo apt-get upgrade -yq > /dev/null 2>&1
        echo "升级已完成"
    fi

    # 选择安装稳定版或测试版
    read -p "请选择安装版本（1: 稳定版, 2: 测试版）: " version_choice
    if [[ "$version_choice" -eq 1 ]]; then
        echo "安装稳定版..."
        sudo apt-get install sing-box -yq > /dev/null 2>&1
        echo "安装已完成"
    elif [[ "$version_choice" -eq 2 ]]; then
        echo "安装测试版..."
        sudo apt-get install sing-box-beta -yq > /dev/null 2>&1
        echo "安装已完成"
    else
        echo "无效的选择"
        exit 1
    fi

    if command -v sing-box &> /dev/null; then
        sing_box_version=$(sing-box version | grep 'sing-box version' | awk '{print $3}')
        echo -e "${CYAN}sing-box 安装成功，版本：${NC} $sing_box_version"
    else
        echo -e "${RED}sing-box 安装失败，请检查日志或网络配置${NC}"
    fi
fi