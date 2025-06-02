# OpenIM Docker 快速启动指南

> 🚀 **一键部署和更新 OpenIM 基于 Anolis OS 8.10 的 Docker 环境**
> 
> **基于官方 docker-compose 配置优化，支持完整的 OpenIM 生态系统**

## 📋 前置条件

- Docker Engine 20.10+
- Docker Compose 2.0+
- 磁盘空间至少 10GB（包含所有服务）
- 内存至少 4GB

## 🎯 镜像说明

### **标签策略**
我们为每个镜像同时提供两种标签：

```bash
# 版本标签（推荐使用）
registry.cn-hangzhou.aliyuncs.com/aspirin2019/openim-server:v3.8.0-anolis

# latest标签
registry.cn-hangzhou.aliyuncs.com/aspirin2019/openim-server:latest-anolis
```

### **服务架构**
```bash
📦 OpenIM 完整架构
├── 🔧 基础组件
│   ├── MongoDB (数据库)
│   ├── Redis (缓存)
│   ├── ETCD (服务发现)
│   ├── Kafka (消息队列)
│   └── MinIO (对象存储)
├── 🚀 核心服务
│   ├── OpenIM Server (核心后端)
│   └── OpenIM Chat (聊天服务)
├── 🌐 前端服务 (可选)
│   ├── Web Frontend (用户界面)
│   └── Admin Frontend (管理界面)
└── 📊 监控服务 (可选)
    ├── Prometheus (监控)
    ├── Grafana (可视化)
    ├── Alertmanager (告警)
    └── Node Exporter (指标)
```

## 🚀 快速部署

### **方式一：一键部署（推荐）**

```bash
# 1. 克隆项目
git clone <your-repo-url>
cd openim-docker

# 2. 部署核心服务（推荐开始）
chmod +x scripts/deploy.sh
./scripts/deploy.sh deploy core

# 3. 部署所有服务（可选）
./scripts/deploy.sh deploy all
```

### **方式二：分阶段部署**

```bash
# 1. 只部署核心服务
./scripts/deploy.sh deploy core

# 2. 添加前端服务
./scripts/deploy.sh deploy frontend

# 3. 添加监控服务
./scripts/deploy.sh deploy monitoring
```

### **方式三：手动部署**

```bash
# 1. 初始化环境文件
cp env.template .env

# 2. 创建数据目录
mkdir -p data/components/{mongodb/data/{db,logs,conf},redis/{data,config},kafka,prometheus/data,grafana,mnt/{data,config}}

# 3. 部署核心服务
docker-compose -f docker-compose.prod.yml up -d mongo redis etcd kafka minio openim-server openim-chat

# 4. 检查服务状态
docker-compose -f docker-compose.prod.yml ps
```

## 🔄 更新镜像

### **自动更新（推荐）**

```bash
# 更新核心服务
./scripts/deploy.sh update core

# 更新所有服务
./scripts/deploy.sh update all
```

### **手动更新**

```bash
# 1. 停止服务
docker-compose -f docker-compose.prod.yml down

# 2. 拉取最新镜像
docker-compose -f docker-compose.prod.yml pull

# 3. 重新启动
docker-compose -f docker-compose.prod.yml up -d
```

## 📊 管理命令

### **基本命令**

```bash
# 查看服务状态
./scripts/deploy.sh status

# 停止服务
./scripts/deploy.sh stop

# 清理容器和未使用镜像
./scripts/deploy.sh cleanup
```

### **日志查看**

```bash
# 核心服务日志
./scripts/deploy.sh logs openim-server       # OpenIM Server
./scripts/deploy.sh logs openim-chat         # OpenIM Chat

# 基础组件日志
./scripts/deploy.sh logs mongo               # MongoDB
./scripts/deploy.sh logs redis               # Redis
./scripts/deploy.sh logs etcd                # ETCD
./scripts/deploy.sh logs kafka               # Kafka
./scripts/deploy.sh logs minio               # MinIO

# 前端服务日志
./scripts/deploy.sh logs openim-web-front    # Web前端
./scripts/deploy.sh logs openim-admin-front  # Admin前端

# 监控服务日志
./scripts/deploy.sh logs prometheus          # Prometheus
./scripts/deploy.sh logs grafana             # Grafana
```

### **危险操作**

```bash
# 完全清理（包括数据）⚠️ 谨慎使用！
./scripts/deploy.sh purge
```

## 🔧 环境配置

### **服务配置文件位置**

```bash
data/
├── components/
│   ├── mongodb/
│   │   ├── data/db/         # MongoDB数据
│   │   ├── data/logs/       # MongoDB日志
│   │   └── data/conf/       # MongoDB配置
│   ├── redis/
│   │   ├── data/            # Redis数据
│   │   └── config/          # Redis配置
│   ├── kafka/               # Kafka数据
│   ├── prometheus/data/     # Prometheus数据
│   ├── grafana/             # Grafana数据
│   └── mnt/                 # MinIO数据
└── .env                     # 环境变量配置
```

### **关键环境变量**

```bash
# 核心镜像版本
OPENIM_SERVER_VERSION=v3.8.0-anolis
MONGODB_VERSION=7.0.4-anolis
REDIS_VERSION=7.2.3-anolis
PRIVATE_CHAT_VERSION=latest-anolis

# 服务端口
OPENIM_API_PORT=10002           # OpenIM API
OPENIM_MSG_GATEWAY_PORT=10001   # OpenIM Gateway
CHAT_API_PORT=10008             # Chat API
ADMIN_API_PORT=10009            # Admin API

# 前端端口
OPENIM_WEB_FRONT_PORT=11001     # Web前端
OPENIM_ADMIN_FRONT_PORT=11002   # Admin前端

# 监控端口
GRAFANA_PORT=13000              # Grafana
PROMETHEUS_PORT=19090           # Prometheus

# MinIO
MINIO_PORT=10005                # MinIO API
MINIO_CONSOLE_PORT=10006        # MinIO 控制台
```

## 🌐 服务地址

### **核心服务**

```bash
OpenIM Server API:    http://localhost:10002
OpenIM Server Gateway: http://localhost:10001
OpenIM Chat API:      http://localhost:10008
OpenIM Admin API:     http://localhost:10009
```

### **基础组件**

```bash
MongoDB:              localhost:27017
Redis:                localhost:6379
ETCD:                 localhost:12379
MinIO Console:        http://localhost:10006
```

### **前端服务（需要启用frontend profile）**

```bash
Web Frontend:         http://localhost:11001
Admin Frontend:       http://localhost:11002
```

### **监控服务（需要启用monitoring profile）**

```bash
Grafana:              http://localhost:13000
Prometheus:           http://localhost:19090
Alertmanager:         http://localhost:19093
```

## 🎛️ Profile 管理

### **可用的 Profiles**

| Profile | 包含服务 | 用途 |
|---------|----------|------|
| `core` | 基础组件 + 核心服务 | 最小化部署，适合开发 |
| `frontend` | 前端服务 | 添加Web界面 |
| `monitoring` | 监控服务 | 添加监控和告警 |
| `all` | 所有服务 | 完整部署，适合生产 |

### **Profile 命令示例**

```bash
# 部署不同的服务组合
./scripts/deploy.sh deploy core         # 最小化部署
./scripts/deploy.sh deploy all          # 完整部署
./scripts/deploy.sh deploy frontend     # 只启动前端
./scripts/deploy.sh deploy monitoring   # 只启动监控

# 更新特定服务组合
./scripts/deploy.sh update core
./scripts/deploy.sh update all
```

## 🔍 故障排除

### **常见问题**

#### **1. 服务启动失败**
```bash
# 检查服务状态
./scripts/deploy.sh status

# 查看具体错误
./scripts/deploy.sh logs <service_name>

# 检查资源使用
docker stats
```

#### **2. 健康检查失败**
```bash
# OpenIM Server 健康检查
curl http://localhost:10002/healthz

# Chat 服务健康检查
curl http://localhost:10008/healthz

# 等待更长时间（服务启动较慢）
sleep 120 && ./scripts/deploy.sh status
```

#### **3. 端口冲突**
```bash
# 检查端口占用
netstat -tulpn | grep :10001
netstat -tulpn | grep :10002

# 修改环境变量中的端口配置
vim .env
```

#### **4. 存储空间不足**
```bash
# 检查磁盘空间
df -h

# 清理未使用的镜像和容器
docker system prune -f

# 清理数据目录（⚠️ 数据会丢失）
./scripts/deploy.sh purge
```

#### **5. MongoDB 认证问题**
```bash
# 检查MongoDB日志
./scripts/deploy.sh logs mongo

# 重新初始化MongoDB
docker-compose -f docker-compose.prod.yml stop mongo
docker volume rm openim-docker_mongodb_data
./scripts/deploy.sh deploy core
```

### **调试技巧**

```bash
# 1. 单独启动有问题的服务
docker-compose -f docker-compose.prod.yml up mongo

# 2. 进入容器调试
docker exec -it openim-server bash
docker exec -it mongo mongosh

# 3. 查看详细日志
docker logs --tail 100 -f openim-server

# 4. 监控资源使用
watch -n 2 'docker stats --no-stream'
```

## 🔐 版本管理

### **自动版本更新**
GitHub Actions 会自动：
1. 检测官方版本更新
2. 构建新的 Anolis 镜像
3. 更新环境配置文件
4. 通知用户更新

### **手动版本管理**
```bash
# 查看当前版本
./scripts/update-env.sh show

# 手动更新版本
./scripts/update-env.sh update-var OPENIM_SERVER_VERSION v3.8.1-anolis

# 备份配置
./scripts/update-env.sh backup

# 恢复配置
./scripts/update-env.sh restore
```

## 🚨 生产环境建议

### **安全配置**
1. 修改所有默认密码
2. 使用强密码策略
3. 配置防火墙规则
4. 启用 SSL/TLS

### **性能优化**
1. 调整 MongoDB WiredTiger 缓存大小
2. 配置 Redis 内存策略
3. 优化 Kafka 分区数量
4. 监控资源使用情况

### **数据备份**
```bash
# MongoDB 备份
docker exec mongo mongodump --out /data/backup

# Redis 备份
docker exec redis redis-cli BGSAVE

# 完整数据备份
tar -czf openim-backup-$(date +%Y%m%d).tar.gz data/
```

### **监控告警**
1. 配置 Prometheus 告警规则
2. 设置 Grafana 仪表盘
3. 配置邮件/钉钉告警
4. 监控关键指标

## 📞 技术支持

### **获取帮助**
1. 查看服务日志定位问题
2. 检查 GitHub Actions 构建状态
3. 参考官方 OpenIM 文档
4. 提交 Issue 到项目仓库

### **社区资源**
- OpenIM 官方文档
- GitHub 讨论区
- 技术交流群
- 故障排除指南

---

🎉 **恭喜！** 您已经成功部署了基于 Anolis OS 8.10 的完整 OpenIM 系统！ 