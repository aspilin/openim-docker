#!/bin/bash

# 测试Chat Dockerfile脚本
# 用于验证修复后的Dockerfile是否能正常构建

set -e

echo "🧪 测试Chat Dockerfile..."

# 验证Dockerfile语法
echo "🔍 验证Dockerfile语法..."
if docker buildx build --dry-run -f dockerfiles/anolis/Dockerfile.openim-chat . > /dev/null 2>&1; then
    echo "✅ Chat Dockerfile语法验证通过"
else
    echo "❌ Chat Dockerfile语法验证失败"
    echo "显示错误详情："
    docker buildx build --dry-run -f dockerfiles/anolis/Dockerfile.openim-chat . 2>&1 | head -20
fi

# 检查关键修复点
echo ""
echo "🔍 检查关键修复点..."

echo "1. 检查运行阶段是否包含wget、tar、gzip："
if grep -A 10 "尝试安装运行时依赖" dockerfiles/anolis/Dockerfile.openim-chat | grep -q "wget"; then
    echo "   ✅ wget已添加"
else
    echo "   ❌ wget未添加"
fi

if grep -A 10 "尝试安装运行时依赖" dockerfiles/anolis/Dockerfile.openim-chat | grep -q "tar"; then
    echo "   ✅ tar已添加"
else
    echo "   ❌ tar未添加"
fi

if grep -A 10 "尝试安装运行时依赖" dockerfiles/anolis/Dockerfile.openim-chat | grep -q "gzip"; then
    echo "   ✅ gzip已添加"
else
    echo "   ❌ gzip未添加"
fi

echo ""
echo "2. 检查Go版本是否为1.22.5："
if grep -q "go1.22.5" dockerfiles/anolis/Dockerfile.openim-chat; then
    echo "   ✅ Go版本已更新到1.22.5"
else
    echo "   ❌ Go版本未更新"
    echo "   当前版本："
    grep "golang.google.cn" dockerfiles/anolis/Dockerfile.openim-chat || echo "   未找到Go下载行"
fi

echo ""
echo "3. 检查端口配置："
if grep -q "EXPOSE 10008 10009" dockerfiles/anolis/Dockerfile.openim-chat; then
    echo "   ✅ Chat端口配置正确 (10008, 10009)"
else
    echo "   ❌ Chat端口配置可能有问题"
fi

echo ""
echo "🎉 Chat Dockerfile检查完成！" 