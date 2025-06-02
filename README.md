# OpenIM Docker 部署 (Anolis OS 8.10)

<div align="center">

[![GitHub release](https://img.shields.io/github/release/aspirin2019/openim-docker.svg)](https://github.com/aspirin2019/openim-docker/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/aspirin2019/openim-server.svg)](https://hub.docker.com/u/aspirin2019)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](https://github.com/aspirin2019/openim-docker/blob/main/LICENSE)
[![Build Status](https://github.com/aspirin2019/openim-docker/workflows/Build%20OpenIM%20Images%20on%20Anolis%20OS%208.10/badge.svg)](https://github.com/aspirin2019/openim-docker/actions)

**基于 Anolis OS 8.10 的 OpenIM 容器化部署方案**

[English](README_EN.md) | 简体中文

</div>

## 🌟 项目特色

- 🚀 **自动化构建**: GitHub Actions 自动监控 OpenIM 官方仓库，检测新版本并自动构建镜像
- 🔄 **双仓库支持**: 同时推送到 Docker Hub 和阿里云镜像仓库，国内外访问都快速
- 🛡️ **安全优化**: 基于 Anolis OS 8.10，非 root 用户运行，多阶段构建，内置健康检查
- 🎯 **简化部署**: 提供交互式部署脚本，一键部署所有服务
- 📊 **完整监控**: 集成 Prometheus + Grafana 监控方案
- 🔧 **易于维护**: 模块化设计，支持独立更新各组件

## 📋 系统要求

- **操作系统**: Linux (推荐 Ubuntu 20.04+, CentOS 8+)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **内存**: 最低 4GB，推荐 8GB+
- **存储**: 最低 20GB 可用空间
- **网络**: 需要访问互联网下载镜像

## 🏗️ 架构说明

### 重构组件 (基于 Anolis OS 8.10)

| 组件 | 镜像标签 | 说明 |
|------|---------|------|
| OpenIM Server | `aspirin2019/openim-server:latest-anolis` | 核心 IM 服务 |
| OpenIM Chat | `aspirin2019/openim-chat:latest-anolis` | 聊天服务 |
| OpenIM Web | `aspirin2019/openim-web:latest-anolis` | Web 前端界面 |
| OpenIM Admin | `aspirin2019/openim-admin:latest-anolis` | 管理后台 |
| MongoDB | `aspirin2019/mongodb:latest-anolis` | 文档数据库 (可选) |
| Redis | `aspirin2019/redis:latest-anolis` | 缓存服务 (可选) |

### 保留官方镜像

- **MySQL**: 关系型数据库
- **MinIO**: 对象存储服务
- **ETCD**: 配置中心
- **Kafka**: 消息队列
- **Prometheus**: 监控数据收集
- **Grafana**: 监控面板

## 🚀 快速开始

### 方式一：一键部署（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/aspirin2019/openim-docker.git
cd openim-docker

# 2. 运行部署脚本
chmod +x scripts/deploy-anolis.sh
./scripts/deploy-anolis.sh

# 3. 选择 "1) 完整部署" 并按提示配置
```

### 方式二：手动部署

```bash
# 1. 准备环境变量
cp env.example .env
vim .env  # 修改配置

# 2. 创建数据目录
mkdir -p {logs,data/{mysql,mongo,redis,minio,etcd}}

# 3. 启动服务
docker-compose up -d

# 4. 检查服务状态
docker-compose ps
```

## ⚙️ 配置说明

### 核心配置项

编辑 `.env` 文件中的关键配置：

```bash
# 服务器配置
OPENIM_IP=192.168.1.100  # 替换为您的服务器IP

# 镜像仓库
IMAGE_REGISTRY=docker.io/aspirin2019
# 或使用阿里云: registry.cn-hangzhou.aliyuncs.com/aspirin2019

# 版本配置
OPENIM_SERVER_VERSION=v3.8.0-anolis
OPENIM_CHAT_VERSION=v1.7.0-anolis

# 安全配置 (请修改默认密码)
MYSQL_PASSWORD=your_secure_password
REDIS_PASSWORD=your_secure_password
SECRET=your_jwt_secret
```

### 端口映射

| 服务 | 访问地址 | 说明 |
|------|---------|------|
| OpenIM Web | http://YOUR_IP:11001 | 用户 Web 界面 |
| OpenIM Admin | http://YOUR_IP:11002 | 管理后台 |
| MinIO Console | http://YOUR_IP:10006 | 文件管理 |
| Grafana | http://YOUR_IP:13000 | 监控面板 |
| Prometheus | http://YOUR_IP:19090 | 监控数据 |

## 🔧 运维管理

### 使用部署脚本管理

```bash
# 交互式管理菜单
./scripts/deploy-anolis.sh

# 命令行操作
./scripts/deploy-anolis.sh start    # 启动服务
./scripts/deploy-anolis.sh stop     # 停止服务
./scripts/deploy-anolis.sh status   # 查看状态
./scripts/deploy-anolis.sh logs     # 查看日志
./scripts/deploy-anolis.sh clean    # 清理数据
```

### Docker Compose 命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f openim-server
docker-compose logs -f openim-chat

# 重启特定服务
docker-compose restart openim-server

# 更新镜像
docker-compose pull
docker-compose up -d
```

## 🔍 故障排查

### 常见问题

1. **服务启动失败**
   ```bash
   # 查看详细日志
   docker-compose logs servicename
   
   # 检查资源使用
   docker stats
   ```

2. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tlnp | grep :10001
   
   # 修改 .env 文件中的端口配置
   ```

3. **权限问题**
   ```bash
   # 修复数据目录权限
   sudo chown -R $(id -u):$(id -g) data/
   chmod -R 755 data/
   ```

### 健康检查

```bash
# API 健康检查
curl http://YOUR_IP:10001/healthz
curl http://YOUR_IP:10008/healthz

# Web 界面检查
curl -I http://YOUR_IP:11001
curl -I http://YOUR_IP:11002
```

## 🔐 安全建议

### 生产环境配置

1. **修改默认密码**
   - 数据库密码
   - JWT 密钥
   - MinIO 访问密钥

2. **网络安全**
   - 配置防火墙规则
   - 使用 HTTPS
   - 限制管理端口访问

3. **数据备份**
   ```bash
   # 数据库备份
   docker-compose exec mysql mysqldump -u root -p openim_v3 > backup.sql
   
   # 文件备份
   tar -czf openim-backup-$(date +%Y%m%d).tar.gz data/
   ```

## 🔄 自动化构建

### GitHub Actions 工作流

本项目配置了自动化构建流程：

- **定时检查**: 每天 UTC 2:00 检查 OpenIM 官方仓库更新
- **版本监控**: 监控 4 个官方仓库的最新 release
- **自动构建**: 检测到新版本时自动构建镜像
- **多平台支持**: 构建 AMD64 和 ARM64 架构
- **双仓库推送**: 同时推送到 Docker Hub 和阿里云

### 配置 GitHub Secrets

在您的 GitHub 仓库中配置以下 Secrets：

```
DOCKERHUB_USERNAME=aspirin2019
DOCKERHUB_TOKEN=your_dockerhub_token
ALIYUN_USERNAME=your_aliyun_username  # 可选
ALIYUN_PASSWORD=your_aliyun_password  # 可选
```

## 📊 监控配置

### Grafana 仪表板

1. 访问 Grafana: `http://YOUR_IP:13000`
2. 默认账户: `admin/admin`
3. 添加 Prometheus 数据源: `http://prometheus:9090`
4. 导入 OpenIM 监控面板

### 监控指标

- 服务健康状态
- API 响应时间
- 数据库连接数
- 内存和 CPU 使用率
- 消息队列状态

## 🌐 集群部署

### Docker Swarm

```bash
# 初始化集群
docker swarm init

# 部署服务栈
docker stack deploy -c docker-compose.yaml openim
```

### Kubernetes

```bash
# 转换配置
kompose convert -f docker-compose.yaml

# 部署到 K8s
kubectl apply -f .
```

## 📚 文档链接

- 📖 [详细使用指南](docs/USAGE.md)
- 🔧 [配置参考](env.example)
- 🐛 [问题反馈](https://github.com/aspirin2019/openim-docker/issues)
- 💬 [讨论区](https://github.com/aspirin2019/openim-docker/discussions)

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支: `git checkout -b feature/amazing-feature`
3. 提交更改: `git commit -m 'Add amazing feature'`
4. 推送分支: `git push origin feature/amazing-feature`
5. 提交 Pull Request

## 📄 许可证

本项目基于 [Apache 2.0](LICENSE) 许可证开源。

## 🙏 致谢

- [OpenIM](https://github.com/openimsdk/open-im-server) - 优秀的开源 IM 解决方案
- [Anolis OS](https://openanolis.cn/) - 稳定可靠的操作系统
- 所有贡献者和用户的支持

---

<div align="center">

**如果这个项目对您有帮助，请给个 ⭐ Star 支持一下！**

Made with ❤️ by [aspirin2019](https://github.com/aspirin2019)

</div>
```

