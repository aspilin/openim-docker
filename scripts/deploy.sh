#!/bin/bash

# OpenIM Docker 部署和更新脚本
# 支持一键部署、更新和清理
# 基于官方 docker-compose 配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env"  # 使用官方标准的 .env 文件
ENV_TEMPLATE="env.template"  # 我们的模板文件
ENV_EXAMPLE="env.example"    # 官方示例文件
DATA_DIR="./data"           # 数据存储目录

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 初始化环境配置
init_env() {
    log_info "初始化环境配置..."
    
    if [[ ! -f "$ENV_FILE" ]]; then
        # 优先使用我们的模板，如果不存在则使用官方示例
        if [[ -f "$ENV_TEMPLATE" ]]; then
            cp "$ENV_TEMPLATE" "$ENV_FILE"
            log_success "从模板创建 $ENV_FILE (使用 $ENV_TEMPLATE)"
        elif [[ -f "$ENV_EXAMPLE" ]]; then
            cp "$ENV_EXAMPLE" "$ENV_FILE"
            log_success "从示例创建 $ENV_FILE (使用 $ENV_EXAMPLE)"
            log_warning "请检查并修改 $ENV_FILE 中的配置"
        else
            log_error "未找到环境配置文件模板 ($ENV_TEMPLATE 或 $ENV_EXAMPLE)"
            exit 1
        fi
    else
        log_info "环境配置文件 $ENV_FILE 已存在"
    fi
    
    # 创建官方数据目录结构
    mkdir -p "$DATA_DIR"/components/{mongodb/data/{db,logs,conf},redis/{data,config},kafka,prometheus/data,grafana,mnt/{data,config}}
    
    # 创建Redis配置文件（如果不存在）
    if [[ ! -f "$DATA_DIR/components/redis/config/redis.conf" ]]; then
        log_info "创建Redis配置文件..."
        cat > "$DATA_DIR/components/redis/config/redis.conf" << 'EOF'
# Redis configuration for OpenIM
bind 0.0.0.0
port 6379
dir /data
appendonly yes
appendfsync everysec
maxmemory-policy allkeys-lru
EOF
    fi
    
    log_success "数据目录和配置文件创建完成"
}

# 显示环境变量文件信息
show_env_info() {
    log_info "环境变量文件信息："
    echo "  ✅ 使用文件: $ENV_FILE"
    if [[ -f "$ENV_FILE" ]]; then
        echo "  📄 文件大小: $(du -h "$ENV_FILE" | cut -f1)"
        echo "  🕐 修改时间: $(stat -c %y "$ENV_FILE" 2>/dev/null || stat -f %Sm "$ENV_FILE" 2>/dev/null || echo "无法获取")"
    fi
    echo "  📝 模板文件: $ENV_TEMPLATE"
    echo "  📋 官方示例: $ENV_EXAMPLE"
}

# 拉取最新镜像
pull_images() {
    log_info "拉取最新镜像..."
    
    # 使用 docker-compose 拉取镜像
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull
    else
        docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull
    fi
    
    log_success "镜像拉取完成"
}

# 清理旧容器和镜像
cleanup() {
    log_info "清理旧容器和镜像..."
    
    # 停止并删除容器
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down --remove-orphans
    else
        docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down --remove-orphans
    fi
    
    # 删除未使用的镜像
    log_info "清理未使用的镜像..."
    docker image prune -f
    
    log_success "清理完成"
}

# 启动服务
start_services() {
    local profile="${1:-core}"
    
    log_info "启动服务 (profile: $profile)..."
    
    case "$profile" in
        core)
            # 启动核心服务（默认）
            if command -v docker-compose &> /dev/null; then
                docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d mongo redis etcd kafka minio openim-server openim-chat
            else
                docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d mongo redis etcd kafka minio openim-server openim-chat
            fi
            ;;
        all)
            # 启动所有服务
            if command -v docker-compose &> /dev/null; then
                docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile frontend --profile monitoring up -d
            else
                docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile frontend --profile monitoring up -d
            fi
            ;;
        frontend)
            # 启动前端服务
            if command -v docker-compose &> /dev/null; then
                docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile frontend up -d
            else
                docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile frontend up -d
            fi
            ;;
        monitoring)
            # 启动监控服务
            if command -v docker-compose &> /dev/null; then
                docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile monitoring up -d
            else
                docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile monitoring up -d
            fi
            ;;
        *)
            log_error "未知的profile: $profile"
            log_info "可用的profiles: core, all, frontend, monitoring"
            exit 1
            ;;
    esac
    
    log_success "服务启动完成"
}

# 检查服务状态
check_health() {
    log_info "检查服务健康状态..."
    
    sleep 20  # 等待服务启动
    
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
    else
        docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
    fi
    
    # 检查健康状态
    log_info "等待服务健康检查..."
    
    local retries=30
    local core_services=("mongo" "redis" "etcd" "kafka" "minio" "openim-server" "openim-chat")
    
    while [[ $retries -gt 0 ]]; do
        local healthy=true
        
        # 检查核心服务健康状态
        for service in "${core_services[@]}"; do
            if docker ps --format 'table {{.Names}}' | grep -q "^${service}$"; then
                local health=$(docker inspect --format='{{.State.Health.Status}}' $service 2>/dev/null || echo "no_health")
                if [[ "$health" == "unhealthy" ]]; then
                    healthy=false
                    log_warning "服务 $service 状态异常"
                    break
                fi
            fi
        done
        
        if $healthy; then
            log_success "核心服务健康检查通过"
            return 0
        fi
        
        echo -n "."
        sleep 5
        ((retries--))
    done
    
    log_warning "健康检查超时，请手动检查服务状态"
}

# 显示服务日志
show_logs() {
    local service=$1
    log_info "显示 $service 服务日志..."
    
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f "$service"
    else
        docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f "$service"
    fi
}

# 完整更新流程
update() {
    local profile="${1:-core}"
    
    log_info "开始更新流程 (profile: $profile)..."
    
    check_dependencies
    show_env_info
    init_env
    cleanup
    pull_images
    start_services "$profile"
    check_health
    
    log_success "更新完成！"
    log_info "您可以使用以下命令查看服务状态："
    log_info "  ./scripts/deploy.sh status"
    log_info "  ./scripts/deploy.sh logs <service_name>"
}

# 首次部署
deploy() {
    local profile="${1:-core}"
    
    log_info "开始首次部署 (profile: $profile)..."
    
    check_dependencies
    show_env_info
    init_env
    pull_images
    start_services "$profile"
    check_health
    
    log_success "部署完成！"
    log_info "服务地址："
    log_info "  OpenIM Server API: http://localhost:10002"
    log_info "  OpenIM Server Gateway: http://localhost:10001"
    log_info "  OpenIM Chat API: http://localhost:10008"
    log_info "  OpenIM Admin API: http://localhost:10009"
    log_info "  MinIO Console: http://localhost:10006"
    
    if [[ "$profile" == "all" || "$profile" == "frontend" ]]; then
        log_info "  Web Frontend: http://localhost:11001"
        log_info "  Admin Frontend: http://localhost:11002"
    fi
    
    if [[ "$profile" == "all" || "$profile" == "monitoring" ]]; then
        log_info "  Grafana: http://localhost:13000"
        log_info "  Prometheus: http://localhost:19090"
    fi
}

# 显示状态
status() {
    log_info "显示服务状态..."
    
    show_env_info
    echo ""
    
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
    else
        docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
    fi
}

# 停止服务
stop() {
    log_info "停止服务..."
    
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" stop
    else
        docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" stop
    fi
    
    log_success "服务已停止"
}

# 完全清理
purge() {
    log_warning "⚠️  这将删除所有容器、镜像和数据！"
    read -p "确认继续？(y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "执行完全清理..."
        
        # 停止并删除容器
        cleanup
        
        # 删除相关镜像
        docker images | grep -E "(aspirin2019|aspirin_private)" | awk '{print $1":"$2}' | xargs -r docker rmi -f
        
        # 删除数据目录
        rm -rf "$DATA_DIR"
        
        log_success "完全清理完成"
    else
        log_info "操作已取消"
    fi
}

# 帮助信息
usage() {
    echo "OpenIM Docker 部署和更新脚本"
    echo ""
    echo "环境变量文件: $ENV_FILE"
    echo "Compose文件: $COMPOSE_FILE"
    echo ""
    echo "用法: $0 [命令] [profile]"
    echo ""
    echo "命令:"
    echo "  deploy [profile]  首次部署服务"
    echo "  update [profile]  更新服务到最新版本"
    echo "  status            显示服务状态"
    echo "  logs <service>    显示服务日志"
    echo "  stop              停止所有服务"
    echo "  cleanup           清理旧容器和镜像"
    echo "  purge             完全清理（包括数据）"
    echo "  help              显示此帮助信息"
    echo ""
    echo "Profiles:"
    echo "  core             核心服务（默认）"
    echo "  all              所有服务（包括前端和监控）"
    echo "  frontend         前端服务"
    echo "  monitoring       监控服务"
    echo ""
    echo "示例:"
    echo "  $0 deploy core              # 部署核心服务"
    echo "  $0 deploy all               # 部署所有服务"
    echo "  $0 update                   # 更新核心服务"
    echo "  $0 logs openim-server       # 查看 server 日志"
    echo "  $0 logs openim-chat         # 查看 chat 日志"
    echo "  $0 logs mongo               # 查看 MongoDB 日志"
}

# 主函数
main() {
    case "${1:-help}" in
        deploy)
            deploy "${2:-core}"
            ;;
        update)
            update "${2:-core}"
            ;;
        status)
            status
            ;;
        logs)
            if [[ -n "$2" ]]; then
                show_logs "$2"
            else
                log_error "请指定服务名称，例如: $0 logs openim-server"
                log_info "可用服务: mongo, redis, etcd, kafka, minio, openim-server, openim-chat"
                exit 1
            fi
            ;;
        stop)
            stop
            ;;
        cleanup)
            cleanup
            ;;
        purge)
            purge
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "未知命令: $1"
            usage
            exit 1
            ;;
    esac
}

# 确保脚本在正确目录执行
if [[ ! -f "$COMPOSE_FILE" ]]; then
    log_error "请在项目根目录执行此脚本"
    exit 1
fi

main "$@" 