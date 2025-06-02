# 私有Chat镜像构建指南

## 📋 前置准备

### 1. GitHub Secrets设置
在 `https://github.com/aspilin/openim-docker/settings/secrets/actions` 中添加：

```
ALIYUN_USERNAME=你的阿里云用户名
ALIYUN_PASSWORD=你的阿里云密码
```

### 2. 阿里云命名空间
确保在阿里云镜像仓库中创建了 `aspirin_private` 命名空间

## 🚀 构建步骤

### 1. 触发构建
- 访问：https://github.com/aspilin/openim-docker/actions
- 选择："Build Private Chat on Anolis OS 8.10"
- 点击："Run workflow"

### 2. 填写参数
```yaml
chat_repo: aspilin/chat
chat_tag: main              # 或 v1.0.0 等特定版本
image_tag: v1.0.0          # 您想要的镜像标签
push_to_private: true      # 勾选推送到私有仓库
```

### 3. 等待构建完成
构建成功后，您将得到镜像：
- `registry.cn-hangzhou.aliyuncs.com/aspirin_private/private-chat:v1.0.0-anolis`
- `registry.cn-hangzhou.aliyuncs.com/aspirin_private/private-chat:latest-anolis`

## 🔄 使用私有镜像

### Docker Compose示例
```yaml
version: '3.8'
services:
  chat:
    image: registry.cn-hangzhou.aliyuncs.com/aspirin_private/private-chat:latest-anolis
    ports:
      - "10008:10008"
      - "10009:10009"
    volumes:
      - ./chat-config:/openim/config
    environment:
      - TZ=Asia/Shanghai
```

### 本地拉取测试
```bash
# 登录阿里云镜像仓库
docker login registry.cn-hangzhou.aliyuncs.com

# 拉取私有镜像
docker pull registry.cn-hangzhou.aliyuncs.com/aspirin_private/private-chat:latest-anolis

# 运行测试
docker run -d --name test-chat \
  -p 10008:10008 \
  registry.cn-hangzhou.aliyuncs.com/aspirin_private/private-chat:latest-anolis
```

## 🔧 故障排查

### 常见问题
1. **无法访问私有仓库**: 检查 GITHUB_TOKEN 权限
2. **阿里云推送失败**: 检查 ALIYUN_USERNAME/PASSWORD
3. **命名空间不存在**: 在阿里云控制台创建 aspirin_private 命名空间

### 检查构建日志
在GitHub Actions页面查看详细的构建日志来诊断问题。 