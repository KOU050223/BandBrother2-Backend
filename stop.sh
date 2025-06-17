#!/bin/bash

# BandBrother2 Backend 停止スクリプト
# このスクリプトは Docker Compose で全サービス（Rails、Go WebSocket、PostgreSQL、Redis）を停止します

echo "🛑 BandBrother2 Backend を停止中..."
echo "=================================="

# 現在のディレクトリを保存
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dockerサービスの停止
echo "🐳 Docker サービスを停止中..."
cd "$SCRIPT_DIR"

if docker-compose ps 2>/dev/null | grep -q "Up"; then
    echo "   Docker Compose サービスを停止します..."
    docker-compose down
    echo "   ✅ Docker サービスを停止しました"
else
    echo "   ℹ️  Docker サービスは実行されていません"
fi

# Docker volumesのクリーンアップ（オプション）
echo ""
echo "🧹 クリーンアップオプション..."
echo "   💡 Docker volumesを削除する場合: docker-compose down -v"
echo "   💡 Docker imagesを削除する場合: docker rmi \$(docker images -q)"

# 最終確認
echo ""
echo "🔍 停止状況の確認..."
echo "=================================="

echo "📦 Docker サービス:"
if docker-compose ps 2>/dev/null | grep -q "Up"; then
    docker-compose ps
else
    echo "   ✅ 全て停止済み"
fi

echo ""
echo "🌐 ポート状況:"
check_port() {
    local port=$1
    local service=$2
    if nc -z localhost $port 2>/dev/null; then
        echo "   ⚠️  ポート $port ($service): まだ使用中"
    else
        echo "   ✅ ポート $port ($service): 解放済み"
    fi
}

check_port 3000 "Rails"
check_port 8080 "WebSocket"
check_port 5432 "PostgreSQL"
check_port 6379 "Redis"

echo ""
echo "✅ BandBrother2 Backend の停止が完了しました！"
