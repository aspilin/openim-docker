#!/bin/bash

# 测试Dockerfile版本更新脚本
# 用于验证sed命令是否正确处理多行ENV格式

set -e

echo "🧪 测试Dockerfile版本更新逻辑..."

# 创建测试用的Dockerfile副本
cp dockerfiles/anolis/Dockerfile.mongodb /tmp/Dockerfile.mongodb.test
cp dockerfiles/anolis/Dockerfile.redis /tmp/Dockerfile.redis.test

echo "📋 原始MongoDB Dockerfile前10行："
head -10 /tmp/Dockerfile.mongodb.test
echo ""

echo "📋 原始Redis Dockerfile前10行："
head -10 /tmp/Dockerfile.redis.test
echo ""

# 测试MongoDB版本更新
echo "🔧 测试MongoDB版本更新..."
NEW_MONGO_VERSION="7.0.8"
sed -i "s/ENV MONGO_VERSION=[0-9.]* \\\\/ENV MONGO_VERSION=${NEW_MONGO_VERSION} \\\\/" /tmp/Dockerfile.mongodb.test

echo "📋 更新后的MongoDB Dockerfile前10行："
head -10 /tmp/Dockerfile.mongodb.test
echo ""

# 测试Redis版本更新  
echo "🔧 测试Redis版本更新..."
NEW_REDIS_VERSION="7.2.5"
sed -i "s/ENV REDIS_VERSION=[0-9.]* \\\\/ENV REDIS_VERSION=${NEW_REDIS_VERSION} \\\\/" /tmp/Dockerfile.redis.test

echo "📋 更新后的Redis Dockerfile前10行："
head -10 /tmp/Dockerfile.redis.test
echo ""

# 验证Dockerfile语法
echo "🔍 验证MongoDB Dockerfile语法..."
if docker buildx build --dry-run -f /tmp/Dockerfile.mongodb.test dockerfiles/anolis/ > /dev/null 2>&1; then
    echo "✅ MongoDB Dockerfile语法验证通过"
else
    echo "❌ MongoDB Dockerfile语法验证失败"
    echo "显示详细内容："
    head -20 /tmp/Dockerfile.mongodb.test
fi

echo "🔍 验证Redis Dockerfile语法..."
if docker buildx build --dry-run -f /tmp/Dockerfile.redis.test dockerfiles/anolis/ > /dev/null 2>&1; then
    echo "✅ Redis Dockerfile语法验证通过"
else
    echo "❌ Redis Dockerfile语法验证失败"
    echo "显示详细内容："
    head -20 /tmp/Dockerfile.redis.test
fi

# 清理测试文件
rm -f /tmp/Dockerfile.mongodb.test /tmp/Dockerfile.redis.test

echo "🎉 测试完成！" 