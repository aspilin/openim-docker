#!/bin/bash

# OpenIM Docker部署脚本 - Anolis OS 8.10版本
# 作者: aspirin2019
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${GREEN}"
    echo "======================================"
    echo "$1"
    echo "======================================"
    echo -e "${NC}"
}

# 检查Docker环境
check_docker() {
    print_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    print_success "Docker环境检查通过"
}

# 创建目录结构
create_directories() {
    print_info "创建必要的目录结构..."
    
    mkdir -p {logs,data/{mysql,mongo,redis,minio,etcd}}
    chmod 755 logs data
    
    print_success "目录结构创建完成"
}

# 配置环境变量
configure_env() {
    print_header "配置环境变量"
    
    if [[ -f .env ]]; then
        print_warning "检测到现有的.env文件"
        read -p "是否要重新配置? (y/N): " overwrite
        if [[ $overwrite != "y" && $overwrite != "Y" ]]; then
            print_info "跳过环境变量配置"
            return
        fi
    fi
    
    cp env.example .env
    
    print_info "请配置以下重要参数:"
    
    # 获取本机IP
    LOCAL_IP=$(ip route get 1 | awk '{print $7}' | head -1)
    print_info "检测到本机IP: ${LOCAL_IP}"
    
    read -p "请输入OpenIM服务IP (默认: ${LOCAL_IP}): " openim_ip
    openim_ip=${openim_ip:-$LOCAL_IP}
    
    read -p "请输入MySQL密码 (默认: openIM123): " mysql_password
    mysql_password=${mysql_password:-openIM123}
    
    read -p "请输入Redis密码 (默认: openIM123): " redis_password
    redis_password=${redis_password:-openIM123}
    
    read -p "请输入MinIO密码 (默认: openIM123): " minio_password
    minio_password=${minio_password:-openIM123}
    
    # 更新.env文件
    sed -i "s/OPENIM_IP=.*/OPENIM_IP=${openim_ip}/" .env
    sed -i "s/MYSQL_PASSWORD=.*/MYSQL_PASSWORD=${mysql_password}/" .env
    sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=${redis_password}/" .env
    sed -i "s/MINIO_SECRET_KEY=.*/MINIO_SECRET_KEY=${minio_password}/" .env
    
    print_success "环境变量配置完成"
}

# 拉取镜像
pull_images() {
    print_header "拉取Docker镜像"
    
    print_info "拉取基于Anolis OS 8.10的OpenIM镜像..."
    
    # 从.env文件读取镜像配置
    source .env
    
    images=(
        "${IMAGE_REGISTRY}/openim-server:${OPENIM_SERVER_VERSION}"
        "${IMAGE_REGISTRY}/openim-chat:${OPENIM_CHAT_VERSION}"
        "${IMAGE_REGISTRY}/openim-web:${OPENIM_WEB_VERSION}"
        "${IMAGE_REGISTRY}/openim-admin:${OPENIM_ADMIN_VERSION}"
    )
    
    for image in "${images[@]}"; do
        print_info "拉取镜像: ${image}"
        docker pull "$image" || print_warning "镜像 ${image} 拉取失败，将在运行时自动拉取"
    done
    
    print_success "镜像拉取完成"
}

# 启动服务
start_services() {
    print_header "启动OpenIM服务"
    
    print_info "启动所有服务..."
    
    # 首先启动基础服务
    print_info "启动基础服务 (MySQL, Redis, MongoDB, ETCD, MinIO, Kafka)..."
    docker-compose up -d mysql redis mongo etcd minio kafka zookeeper prometheus grafana
    
    # 等待基础服务启动
    print_info "等待基础服务启动..."
    sleep 30
    
    # 启动OpenIM核心服务
    print_info "启动OpenIM核心服务..."
    docker-compose up -d openim-server openim-chat
    
    # 等待核心服务启动
    print_info "等待核心服务启动..."
    sleep 20
    
    # 启动Web服务
    print_info "启动Web界面..."
    docker-compose up -d openim-web openim-admin
    
    print_success "所有服务启动完成"
}

# 检查服务状态
check_services() {
    print_header "检查服务状态"
    
    print_info "服务运行状态:"
    docker-compose ps
    
    echo ""
    print_info "检查服务健康状态..."
    
    # 检查核心服务
    services=("openim-server" "openim-chat" "mysql" "redis" "mongo")
    
    for service in "${services[@]}"; do
        if docker-compose ps | grep -q "${service}.*Up"; then
            print_success "${service}: 运行中"
        else
            print_error "${service}: 未运行"
        fi
    done
}

# 显示访问信息
show_access_info() {
    print_header "访问信息"
    
    source .env
    
    echo -e "${GREEN}OpenIM部署完成！访问信息如下:${NC}"
    echo ""
    echo -e "${BLUE}Web界面:${NC}"
    echo "  - OpenIM Web:    http://${OPENIM_IP}:${OPENIM_WEB_PORT}"
    echo "  - OpenIM Admin:  http://${OPENIM_IP}:${OPENIM_ADMIN_PORT}"
    echo ""
    echo -e "${BLUE}API服务:${NC}"
    echo "  - OpenIM API:    http://${OPENIM_IP}:${API_OPENIM_PORT}"
    echo "  - Chat API:      http://${OPENIM_IP}:${API_CHAT_PORT}"
    echo ""
    echo -e "${BLUE}管理工具:${NC}"
    echo "  - MinIO Console: http://${OPENIM_IP}:10006"
    echo "  - Grafana:       http://${OPENIM_IP}:${GRAFANA_PORT} (admin/admin)"
    echo "  - Prometheus:    http://${OPENIM_IP}:${PROMETHEUS_PORT}"
    echo ""
    echo -e "${BLUE}数据库连接:${NC}"
    echo "  - MySQL:         ${OPENIM_IP}:${MYSQL_PORT} (${MYSQL_USERNAME}/${MYSQL_PASSWORD})"
    echo "  - Redis:         ${OPENIM_IP}:${REDIS_PORT}"
    echo "  - MongoDB:       ${OPENIM_IP}:${MONGO_PORT}"
    echo ""
    echo -e "${YELLOW}注意: 首次启动可能需要几分钟时间初始化数据库${NC}"
}

# 停止服务
stop_services() {
    print_header "停止OpenIM服务"
    
    print_info "停止所有服务..."
    docker-compose down
    
    print_success "服务已停止"
}

# 清理数据
cleanup_data() {
    print_header "清理数据"
    
    print_warning "此操作将删除所有数据，包括数据库、文件等"
    read -p "确认要清理所有数据吗? (y/N): " confirm
    
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        print_info "停止服务..."
        docker-compose down -v
        
        print_info "删除数据目录..."
        rm -rf data logs
        
        print_success "数据清理完成"
    else
        print_info "取消清理操作"
    fi
}

# 查看日志
view_logs() {
    print_header "查看服务日志"
    
    echo "可用的服务:"
    docker-compose ps --services
    echo ""
    
    read -p "请输入要查看日志的服务名: " service_name
    
    if [[ -n $service_name ]]; then
        docker-compose logs -f "$service_name"
    else
        docker-compose logs -f
    fi
}

# 主菜单
show_menu() {
    echo -e "${GREEN}"
    echo "======================================"
    echo "  OpenIM Docker 部署脚本 (Anolis版)"
    echo "======================================"
    echo -e "${NC}"
    echo "1) 完整部署 (推荐新用户)"
    echo "2) 配置环境变量"
    echo "3) 拉取镜像"
    echo "4) 启动服务"
    echo "5) 停止服务"
    echo "6) 检查服务状态"
    echo "7) 查看访问信息"
    echo "8) 查看日志"
    echo "9) 清理数据"
    echo "0) 退出"
    echo ""
}

# 完整部署流程
full_deploy() {
    print_header "开始完整部署流程"
    
    check_docker
    create_directories
    configure_env
    pull_images
    start_services
    
    print_info "等待服务完全启动..."
    sleep 30
    
    check_services
    show_access_info
    
    print_success "OpenIM部署完成！"
}

# 主程序
main() {
    # 检查是否在正确的目录
    if [[ ! -f docker-compose.yaml ]]; then
        print_error "请在包含docker-compose.yaml的目录中运行此脚本"
        exit 1
    fi
    
    if [[ $# -eq 0 ]]; then
        # 交互模式
        while true; do
            show_menu
            read -p "请选择操作 (0-9): " choice
            
            case $choice in
                1) full_deploy ;;
                2) configure_env ;;
                3) pull_images ;;
                4) start_services ;;
                5) stop_services ;;
                6) check_services ;;
                7) show_access_info ;;
                8) view_logs ;;
                9) cleanup_data ;;
                0) print_info "退出脚本"; exit 0 ;;
                *) print_error "无效选择，请重新输入" ;;
            esac
            
            echo ""
            read -p "按回车键继续..."
            clear
        done
    else
        # 命令行模式
        case $1 in
            deploy) full_deploy ;;
            start) start_services ;;
            stop) stop_services ;;
            status) check_services ;;
            logs) view_logs ;;
            clean) cleanup_data ;;
            *) 
                echo "用法: $0 [deploy|start|stop|status|logs|clean]"
                echo "或直接运行 $0 进入交互模式"
                exit 1
                ;;
        esac
    fi
}

# 脚本入口
main "$@" 
