# OpenIM Docker 部署指南 (Anolis OS 8.10)

## 📖 概述

本项目提供基于 Anolis OS 8.10 的 OpenIM Docker 镜像构建和部署方案，支持：

- 🚀 **自动构建**: GitHub Actions 自动监控版本更新并构建镜像
- 🔄 **双仓库支持**: 同时推送到 Docker Hub 和阿里云镜像仓库
- 🛡️ **安全优化**: 非 root 用户运行，多阶段构建，健康检查
- 🎯 **简化部署**: 交互式部署脚本，一键部署所有服务

## 🏗️ 架构说明

### 镜像组件

**基于 Anolis OS 8.10 重构的组件**:
- ✅ `openim-server` - OpenIM 核心服务 (Go 1.21.5)
- ✅ `openim-chat` - 聊天服务
- ✅ `openim-web` - Web 前端 (Node.js + Nginx)
- ✅ `openim-admin` - 管理后台 (Node.js + Nginx)
- ✅ `mongodb` - MongoDB 7.0 (可选)
- ✅ `redis` - Redis 7.2 (可选)

**保留官方镜像的组件**:
- MinIO, ETCD, Kafka, Prometheus, Grafana, MySQL

## 🚀 快速开始

### 方式一：使用部署脚本（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/aspilin/openim-docker.git
cd openim-docker

# 2. 给脚本执行权限
chmod +x scripts/deploy-anolis.sh

# 3. 运行部署脚本
./scripts/deploy-anolis.sh

# 选择 "1) 完整部署" 即可
```

### 方式二：手动部署

```bash
# 1. 复制环境变量文件
cp env.example .env

# 2. 编辑配置（重要）
vim .env
# 修改 OPENIM_IP 为您的服务器IP
# 修改密码等敏感信息

# 3. 创建数据目录
mkdir -p {logs,data/{mysql,mongo,redis,minio,etcd}}

# 4. 启动服务
docker-compose up -d
```

## ⚙️ 配置说明

### 环境变量文件 (.env)

主要配置项：

```bash
# 基础配置
OPENIM_IP=192.168.1.100              # 您的服务器IP
IMAGE_REGISTRY=docker.io/aspirin2019     # 镜像仓库

# 版本配置
OPENIM_SERVER_VERSION=v3.8.0-anolis
OPENIM_CHAT_VERSION=v1.7.0-anolis
OPENIM_WEB_VERSION=v3.8.0-anolis
OPENIM_ADMIN_VERSION=v1.7.0-anolis

# 数据库密码
MYSQL_PASSWORD=your_secure_password
REDIS_PASSWORD=your_secure_password
MONGO_PASSWORD=your_secure_password
```

### 端口映射

| 服务 | 内部端口 | 外部端口 | 说明 |
|------|---------|---------|------|
| OpenIM Web | 80 | 11001 | Web 前端界面 |
| OpenIM Admin | 80 | 11002 | 管理后台界面 |
| OpenIM API | 10001 | 10001 | API 服务 |
| Chat API | 10008 | 10008 | 聊天 API |
| MySQL | 3306 | 13306 | 数据库 |
| Redis | 6379 | 16379 | 缓存 |
| MongoDB | 27017 | 37017 | 文档数据库 |
| MinIO | 9000 | 10005 | 对象存储 |
| MinIO Console | 9001 | 10006 | MinIO 管理界面 |
| Grafana | 3000 | 13000 | 监控面板 |

## 🔧 运维操作

### 基本操作

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f openim-server
docker-compose logs -f openim-chat

# 重启服务
docker-compose restart openim-server

# 停止所有服务
docker-compose down

# 停止并删除数据
docker-compose down -v
```

### 使用部署脚本管理

```bash
# 进入交互式管理菜单
./scripts/deploy-anolis.sh

# 或直接使用命令
./scripts/deploy-anolis.sh start    # 启动服务
./scripts/deploy-anolis.sh stop     # 停止服务
./scripts/deploy-anolis.sh status   # 查看状态
./scripts/deploy-anolis.sh logs     # 查看日志
./scripts/deploy-anolis.sh clean    # 清理数据
```

### 健康检查

```bash
# 检查服务健康状态
curl http://YOUR_IP:10001/healthz
curl http://YOUR_IP:10008/healthz

# 检查 Web 界面
curl http://YOUR_IP:11001
curl http://YOUR_IP:11002
```

## 🔍 故障排查

### 常见问题

1. **服务启动失败**
   ```bash
   # 查看详细日志
   docker-compose logs servicename
   
   # 检查端口占用
   netstat -tlnp | grep :10001
   ```

2. **数据库连接失败**
   ```bash
   # 检查数据库是否启动
   docker-compose ps mysql mongo redis
   
   # 测试数据库连接
   docker-compose exec mysql mysql -u root -p
   ```

3. **权限问题**
   ```bash
   # 修复数据目录权限
   sudo chown -R 1001:1001 data/
   chmod -R 755 data/
   ```

4. **内存不足**
   ```bash
   # 检查系统资源
   free -h
   df -h
   
   # 清理 Docker 缓存
   docker system prune -a
   ```

### 性能调优

1. **数据库优化**
   ```bash
   # MySQL 配置优化（在 docker-compose.yaml 中）
   - --innodb-buffer-pool-size=1G
   - --max-connections=1000
   
   # MongoDB 配置优化
   # 编辑 dockerfiles/anolis/mongod.conf
   ```

2. **Redis 调优**
   ```bash
   # 编辑 dockerfiles/anolis/redis.conf
   maxmemory 2gb
   maxmemory-policy allkeys-lru
   ```

## 🔐 安全建议

### 生产环境安全配置

1. **修改默认密码**
   ```bash
   # 在 .env 文件中修改所有默认密码
   MYSQL_PASSWORD=your_strong_password
   REDIS_PASSWORD=your_strong_password
   MONGO_PASSWORD=your_strong_password
   SECRET=your_jwt_secret
   ```

2. **启用 HTTPS**
   ```bash
   # 在 nginx.conf 中配置 SSL
   # 或使用反向代理（如 Nginx、Traefik）
   ```

3. **网络安全**
   ```bash
   # 只暴露必要的端口
   # 使用防火墙限制访问
   # 配置内部网络通信
   ```

4. **数据备份**
   ```bash
   # MySQL 备份
   docker-compose exec mysql mysqldump -u root -p openim_v3 > backup.sql
   
   # MongoDB 备份
   docker-compose exec mongo mongodump --out /backup
   
   # 文件备份
   tar -czf openim-backup-$(date +%Y%m%d).tar.gz data/
   ```

## 📊 监控配置

### Grafana 仪表板

1. 访问 Grafana: `http://YOUR_IP:13000`
2. 默认账户: `admin/admin`
3. 导入 OpenIM 监控面板
4. 配置 Prometheus 数据源: `http://prometheus:9090`

### Prometheus 配置

```yaml
# prometheus.yml 配置示例
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'openim-server'
    static_configs:
      - targets: ['openim-server:10001']
  
  - job_name: 'openim-chat'
    static_configs:
      - targets: ['openim-chat:10008']
```

## 🌐 集群部署

### Docker Swarm 部署

```bash
# 初始化 Swarm
docker swarm init

# 部署堆栈
docker stack deploy -c docker-compose.yaml openim

# 查看服务
docker service ls
```

### Kubernetes 部署

```bash
# 生成 Kubernetes 配置
kompose convert -f docker-compose.yaml

# 部署到 K8s
kubectl apply -f .
```

## 🔄 更新升级

### 手动更新

```bash
# 1. 停止服务
docker-compose down

# 2. 拉取最新镜像
docker-compose pull

# 3. 重新启动
docker-compose up -d
```

### 自动更新

GitHub Actions 工作流会自动：
1. 检查 OpenIM 官方仓库新版本
2. 构建新的镜像
3. 推送到镜像仓库
4. 更新 `versions.txt` 文件

## 📝 开发说明

### 自定义镜像构建

```bash
# 构建基础镜像
docker build -f dockerfiles/anolis/Dockerfile.base -t your-registry/openim-base:anolis .

# 构建服务镜像
docker build -f dockerfiles/anolis/Dockerfile.openim-server -t your-registry/openim-server:latest .
```

### 本地开发环境

```bash
# 使用开发配置
cp env.example .env.dev
# 修改配置用于开发

# 启动开发环境
docker-compose -f docker-compose.yaml -f docker-compose.dev.yaml up -d
```

## 📞 技术支持

- 🐛 **问题反馈**: [GitHub Issues](https://github.com/aspilin/openim-docker/issues)
- 📖 **官方文档**: [OpenIM 文档](https://docs.openim.io/)
- 💬 **社区讨论**: [OpenIM 社区](https://github.com/openimsdk/open-im-server/discussions)

## 📄 许可证

本项目基于 Apache 2.0 许可证开源。详见 [LICENSE](LICENSE) 文件。

---

*最后更新: 2024年6月* 