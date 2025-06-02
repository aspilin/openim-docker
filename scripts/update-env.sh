#!/bin/bash

# 环境变量更新脚本
# 用于 GitHub Actions 自动更新 .env 文件中的镜像版本

set -e

ENV_FILE=".env"
ENV_TEMPLATE="env.template"
ENV_EXAMPLE="env.example"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 更新指定的环境变量
update_env_var() {
    local var_name="$1"
    local new_value="$2"
    local file="${3:-$ENV_FILE}"
    
    if [[ -z "$var_name" || -z "$new_value" ]]; then
        log_error "变量名和值不能为空"
        return 1
    fi
    
    # 确保文件存在
    if [[ ! -f "$file" ]]; then
        if [[ -f "$ENV_TEMPLATE" ]]; then
            cp "$ENV_TEMPLATE" "$file"
            log_info "从模板创建 $file"
        elif [[ -f "$ENV_EXAMPLE" ]]; then
            cp "$ENV_EXAMPLE" "$file"
            log_info "从示例创建 $file"
        else
            log_error "文件 $file 不存在，且未找到模板文件"
            return 1
        fi
    fi
    
    # 更新变量值
    if grep -q "^${var_name}=" "$file"; then
        # 变量存在，更新值
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i "" "s/^${var_name}=.*/${var_name}=${new_value}/" "$file"
        else
            # Linux
            sed -i "s/^${var_name}=.*/${var_name}=${new_value}/" "$file"
        fi
        log_success "更新 ${var_name}=${new_value}"
    else
        # 变量不存在，添加到文件末尾
        echo "${var_name}=${new_value}" >> "$file"
        log_success "添加 ${var_name}=${new_value}"
    fi
}

# 批量更新镜像版本
update_images() {
    local server_version="$1"
    local mongodb_version="$2"
    local redis_version="$3"
    local chat_version="$4"
    
    log_info "开始批量更新镜像版本..."
    
    if [[ -n "$server_version" ]]; then
        update_env_var "OPENIM_SERVER_VERSION" "$server_version"
    fi
    
    if [[ -n "$mongodb_version" ]]; then
        update_env_var "MONGODB_VERSION" "$mongodb_version"
    fi
    
    if [[ -n "$redis_version" ]]; then
        update_env_var "REDIS_VERSION" "$redis_version"
    fi
    
    if [[ -n "$chat_version" ]]; then
        update_env_var "PRIVATE_CHAT_VERSION" "$chat_version"
    fi
    
    log_success "镜像版本更新完成"
}

# 显示当前版本
show_versions() {
    log_info "当前镜像版本："
    
    if [[ -f "$ENV_FILE" ]]; then
        echo "----------------------------------------"
        echo "文件: $ENV_FILE"
        grep -E "^(OPENIM_SERVER_VERSION|MONGODB_VERSION|REDIS_VERSION|PRIVATE_CHAT_VERSION)=" "$ENV_FILE" || echo "未找到版本信息"
        echo "----------------------------------------"
    else
        log_error "环境文件 $ENV_FILE 不存在"
    fi
}

# 显示所有环境变量文件的差异
compare_env_files() {
    log_info "环境变量文件对比："
    
    local files=("$ENV_FILE" "$ENV_TEMPLATE" "$ENV_EXAMPLE")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "📄 $file ($(wc -l < "$file") 行, $(du -h "$file" | cut -f1))"
        else
            echo "❌ $file (不存在)"
        fi
    done
    
    echo ""
    
    # 显示关键差异
    if [[ -f "$ENV_TEMPLATE" && -f "$ENV_EXAMPLE" ]]; then
        log_info "关键配置差异："
        echo "我们的模板 vs 官方示例："
        echo "- OPENIM_CHAT_IMAGE 配置不同"
        echo "- 镜像仓库配置不同"
        echo "- 版本变量名不同"
    fi
}

# 验证环境文件
validate_env() {
    log_info "验证环境文件..."
    
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error "环境文件 $ENV_FILE 不存在"
        return 1
    fi
    
    # 检查必需的变量
    local required_vars=(
        "OPENIM_SERVER_IMAGE"
        "OPENIM_CHAT_IMAGE"
        "MONGO_IMAGE"
        "REDIS_IMAGE"
    )
    
    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" "$ENV_FILE"; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "缺少必需的环境变量: ${missing_vars[*]}"
        return 1
    fi
    
    # 检查OPENIM_CHAT_IMAGE配置是否正确
    local chat_image=$(grep "^OPENIM_CHAT_IMAGE=" "$ENV_FILE" | cut -d'=' -f2)
    if [[ "$chat_image" == *"aspirin2019"* ]]; then
        log_warning "检测到错误配置: OPENIM_CHAT_IMAGE 应该使用私有仓库"
        log_info "建议配置: OPENIM_CHAT_IMAGE=\${REGISTRY}/\${PRIVATE_NAMESPACE}/private-chat:\${PRIVATE_CHAT_VERSION}"
    fi
    
    log_success "环境文件验证完成"
}

# 备份环境文件
backup_env() {
    if [[ -f "$ENV_FILE" ]]; then
        local backup_file="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$ENV_FILE" "$backup_file"
        log_success "环境文件已备份到 $backup_file"
    fi
}

# 恢复环境文件
restore_env() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        # 查找最新的备份文件
        backup_file=$(ls -t "${ENV_FILE}.backup."* 2>/dev/null | head -1)
        if [[ -z "$backup_file" ]]; then
            log_error "未找到备份文件"
            return 1
        fi
    fi
    
    if [[ -f "$backup_file" ]]; then
        cp "$backup_file" "$ENV_FILE"
        log_success "环境文件已从 $backup_file 恢复"
    else
        log_error "备份文件 $backup_file 不存在"
        return 1
    fi
}

# 修复OPENIM_CHAT_IMAGE配置
fix_chat_image() {
    log_info "修复 OPENIM_CHAT_IMAGE 配置..."
    
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error "环境文件 $ENV_FILE 不存在"
        return 1
    fi
    
    # 备份文件
    backup_env
    
    # 修复配置
    update_env_var "OPENIM_CHAT_IMAGE" "\${REGISTRY}/\${PRIVATE_NAMESPACE}/private-chat:\${PRIVATE_CHAT_VERSION}"
    
    log_success "OPENIM_CHAT_IMAGE 配置已修复"
}

# 帮助信息
usage() {
    echo "环境变量更新脚本"
    echo ""
    echo "用法: $0 [命令] [参数...]"
    echo ""
    echo "命令:"
    echo "  update-var <变量名> <值>           更新指定环境变量"
    echo "  update-images <server> <mongo> <redis> <chat>  批量更新镜像版本"
    echo "  show                             显示当前版本"
    echo "  compare                          对比环境变量文件"
    echo "  validate                         验证环境文件"
    echo "  backup                           备份环境文件"
    echo "  restore [备份文件]                恢复环境文件"
    echo "  fix-chat                         修复OPENIM_CHAT_IMAGE配置"
    echo "  help                             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 update-var OPENIM_SERVER_VERSION v3.8.1-anolis"
    echo "  $0 update-images v3.8.1-anolis 7.0.5-anolis 7.2.4-anolis latest-anolis"
    echo "  $0 show"
    echo "  $0 compare"
    echo "  $0 fix-chat"
}

# 主函数
main() {
    case "${1:-help}" in
        update-var)
            if [[ $# -lt 3 ]]; then
                log_error "参数不足，用法: $0 update-var <变量名> <值>"
                exit 1
            fi
            backup_env
            update_env_var "$2" "$3"
            ;;
        update-images)
            if [[ $# -lt 5 ]]; then
                log_error "参数不足，用法: $0 update-images <server> <mongo> <redis> <chat>"
                exit 1
            fi
            backup_env
            update_images "$2" "$3" "$4" "$5"
            ;;
        show)
            show_versions
            ;;
        compare)
            compare_env_files
            ;;
        validate)
            validate_env
            ;;
        backup)
            backup_env
            ;;
        restore)
            restore_env "$2"
            ;;
        fix-chat)
            fix_chat_image
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

main "$@"