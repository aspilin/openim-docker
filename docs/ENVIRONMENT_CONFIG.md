# OpenIM Docker 环境配置详解

## 🎯 **配置文件体系说明**

### **配置文件层次结构**

```
openim-docker/
├── .env                    # 实际使用的环境配置文件 (用户可修改)
├── env.template            # 我们的标准模板 (正确配置)
├── env.example             # 官方示例文件 (已修正错误)
└── scripts/
    ├── deploy.sh           # 部署脚本 (首次使用逻辑)
    └── update-env.sh       # 环境变量更新脚本
```

## 🔄 **首次使用 vs 二次使用逻辑**

### **首次使用判断机制**

部署脚本中的 `init_env()` 函数通过检查 `.env` 文件是否存在来判断：

```bash
if [[ ! -f "$ENV_FILE" ]]; then
    # 👇 首次使用：从模板创建 .env 文件
    if [[ -f "$ENV_TEMPLATE" ]]; then
        cp "$ENV_TEMPLATE" "$ENV_FILE"
        log_success "从模板创建 $ENV_FILE (使用 $ENV_TEMPLATE)"
    elif [[ -f "$ENV_EXAMPLE" ]]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        log_success "从示例创建 $ENV_FILE (使用 $ENV_EXAMPLE)"
    fi
else
    # 👇 二次使用：保护现有配置
    log_info "环境配置文件 $ENV_FILE 已存在"
fi
```

### **使用流程对比**

| 场景 | 判断条件 | 执行操作 | 结果 |
|------|----------|----------|------|
| **首次部署** | `.env` 文件不存在 | 复制 `env.template` → `.env` | ✅ 创建新的配置文件 |
| **二次部署** | `.env` 文件存在 | 不做任何修改 | ✅ 保护用户自定义配置 |
| **强制重置** | 手动删除 `.env` | 重新从模板创建 | ⚠️ 会丢失自定义配置 |

## 📋 **配置文件内容对比**

### **1. env.template (我们的正确模板)**

**特点：**
- ✅ 使用变量替换系统 `${REGISTRY}/${NAMESPACE}`
- ✅ 正确的私有Chat仓库配置
- ✅ 标准化的变量命名
- ✅ 完整的官方配置兼容

**关键配置：**
```bash
# 镜像仓库配置
REGISTRY=registry.cn-hangzhou.aliyuncs.com
PUBLIC_NAMESPACE=aspirin2019
PRIVATE_NAMESPACE=aspirin_private

# 核心服务镜像 (正确配置)
OPENIM_SERVER_IMAGE=${REGISTRY}/${PUBLIC_NAMESPACE}/openim-server:${OPENIM_SERVER_VERSION}
OPENIM_CHAT_IMAGE=${REGISTRY}/${PRIVATE_NAMESPACE}/private-chat:${PRIVATE_CHAT_VERSION}  # ✅ 私有仓库

# 前端服务镜像 (使用官方镜像)
OPENIM_WEB_FRONT_IMAGE=openim/openim-web:latest      # ✅ 官方镜像
OPENIM_ADMIN_FRONT_IMAGE=openim/openim-admin:latest  # ✅ 官方镜像
```

### **2. env.example (官方示例，已修正)**

**修正前的问题：**
```bash
OPENIM_CHAT_IMAGE=aspirin2019/openim-chat:latest-anolis  # ❌ 错误：应该用私有仓库
```

**修正后：**
```bash
OPENIM_CHAT_IMAGE=registry.cn-hangzhou.aliyuncs.com/aspirin_private/private-chat:latest-anolis  # ✅ 正确
```

## 🛠️ **环境变量更新机制**

### **自动更新 (CI/CD)**

GitHub Actions 会自动调用 `update-env.sh` 脚本：

```bash
# 批量更新镜像版本
./scripts/update-env.sh update-images v3.8.1-anolis 7.0.5-anolis 7.2.4-anolis latest-anolis
```

### **手动更新**

```bash
# 更新单个变量
./scripts/update-env.sh update-var OPENIM_SERVER_VERSION v3.8.1-anolis

# 修复Chat配置
./scripts/update-env.sh fix-chat

# 查看当前版本
./scripts/update-env.sh show

# 比较配置文件
./scripts/update-env.sh compare
```

## 🎭 **镜像仓库策略**

### **镜像分类和仓库分配**

| 服务类型 | 镜像名称 | 仓库类型 | 构建方式 | 原因 |
|---------|----------|----------|----------|------|
| **核心服务** | `openim-server` | 公共仓库 `aspirin2019` | 自动构建 Anolis 版本 | 提供优化的基础镜像 |
| **Chat服务** | `private-chat` | 私有仓库 `aspirin_private` | 手动构建私有版本 | 支持定制化功能 |
| **前端服务** | `openim-web`<br>`openim-admin` | 官方镜像 | 不构建 | 前端更新频率低，官方版本足够 |
| **基础组件** | `mongodb`<br>`redis` | 公共仓库 `aspirin2019` | 可选构建 Anolis 版本 | 提供统一的基础环境 |

### **镜像仓库地址**

```bash
# 公共仓库 (免费)
registry.cn-hangzhou.aliyuncs.com/aspirin2019/openim-server:latest-anolis
registry.cn-hangzhou.aliyuncs.com/aspirin2019/mongodb:latest-anolis
registry.cn-hangzhou.aliyuncs.com/aspirin2019/redis:latest-anolis

# 私有仓库 (免费额度)
registry.cn-hangzhou.aliyuncs.com/aspirin_private/private-chat:latest-anolis

# 官方镜像
openim/openim-web:latest
openim/openim-admin:latest
```

## 🔧 **配置自定义指南**

### **修改服务器IP地址**

编辑 `.env` 文件：

```bash
# 修改这些变量为您的实际IP
SERVER_IP=192.168.1.100
OPENIM_IP=${SERVER_IP}
MINIO_IP=${SERVER_IP}
MINIO_EXTERNAL_ADDRESS="http://${SERVER_IP}:10005"
API_URL=http://${SERVER_IP}:10008
GRAFANA_URL=http://${SERVER_IP}:13000
```

### **修改默认密码**

```bash
# 数据库密码
MONGO_PASSWORD=your_secure_password
REDIS_PASSWORD=your_secure_password

# OpenIM密钥
OPENIM_SECRET=your_secure_secret

# MinIO密钥
MINIO_ACCESS_KEY_ID=your_access_key
MINIO_SECRET_ACCESS_KEY=your_secret_key
```

### **启用不同的服务组合**

```bash
# 只启动核心服务
./scripts/deploy.sh deploy core

# 启动所有服务（包括前端和监控）
./scripts/deploy.sh deploy all

# 只启动前端服务
./scripts/deploy.sh deploy frontend

# 只启动监控服务
./scripts/deploy.sh deploy monitoring
```

## 🚨 **配置验证和故障排查**

### **验证配置文件**

```bash
# 验证环境文件
./scripts/update-env.sh validate

# 检查配置文件对比
./scripts/update-env.sh compare
```

### **备份和恢复配置**

```bash
# 备份当前配置
./scripts/update-env.sh backup

# 恢复到最新备份
./scripts/update-env.sh restore

# 恢复到指定备份
./scripts/update-env.sh restore .env.backup.20240101_120000
```

### **常见配置问题**

| 问题 | 症状 | 解决方案 |
|------|------|----------|
| **Chat镜像配置错误** | Chat服务无法启动 | `./scripts/update-env.sh fix-chat` |
| **IP地址未修改** | 外部无法访问服务 | 编辑 `.env` 中的 `SERVER_IP` |
| **密码冲突** | 数据库连接失败 | 确保 `.env` 和数据库中的密码一致 |
| **端口冲突** | 服务启动失败 | 修改 `.env` 中的端口配置 |

## 🎯 **最佳实践建议**

### **1. 首次部署**
```bash
# 1. 运行部署脚本（会自动创建.env）
./scripts/deploy.sh deploy core

# 2. 根据需要修改.env配置
vim .env

# 3. 重新部署应用新配置
./scripts/deploy.sh update core
```

### **2. 生产环境配置**
```bash
# 1. 修改所有默认密码
# 2. 设置正确的服务器IP
# 3. 配置SSL/TLS证书
# 4. 设置防火墙规则
# 5. 启用监控服务
./scripts/deploy.sh deploy all
```

### **3. 开发环境配置**
```bash
# 只启动核心服务，节省资源
./scripts/deploy.sh deploy core
```

## 📝 **配置文件模板示例**

### **最小化配置 (.env)**
```bash
# 基础配置
SERVER_IP=127.0.0.1
OPENIM_SECRET=openIM123

# 镜像配置
OPENIM_SERVER_IMAGE=registry.cn-hangzhou.aliyuncs.com/aspirin2019/openim-server:latest-anolis
OPENIM_CHAT_IMAGE=registry.cn-hangzhou.aliyuncs.com/aspirin_private/private-chat:latest-anolis
```

### **生产环境配置 (.env)**
```bash
# 服务器配置
SERVER_IP=192.168.1.100
OPENIM_SECRET=your_production_secret

# 数据库配置
MONGO_PASSWORD=secure_mongo_password
REDIS_PASSWORD=secure_redis_password

# 对象存储配置
MINIO_ACCESS_KEY_ID=production_access_key
MINIO_SECRET_ACCESS_KEY=production_secret_key

# 镜像配置
OPENIM_SERVER_IMAGE=registry.cn-hangzhou.aliyuncs.com/aspirin2019/openim-server:v3.8.1-anolis
OPENIM_CHAT_IMAGE=registry.cn-hangzhou.aliyuncs.com/aspirin_private/private-chat:v1.7.0-anolis
```

---

**总结：** 配置系统通过智能的首次使用检测、模板文件继承和自动备份机制，既保证了配置的正确性，又保护了用户的自定义设置。前端服务已正确配置为使用官方镜像，避免了不必要的构建开销。 